"""
Watcher — monitora roteiros/ (PDFs) e models_to_process/ (RBXMs).
Quando detecta um PDF + pelo menos 1 RBXM com o mesmo prefixo de nome,
dispara process_group() após um debounce de 5s (aguarda múltiplos RBXMs).

Convenção de nomes:
  PDF:   roteiro-nome.pdf
  RBXMs: roteiro-nome.rbxm          ← aceito (stem idêntico)
         roteiro-nome-layout.rbxm   ← aceito (stem com sufixo '-...')
         roteiro-nome-vfx.rbxm      ← aceito
"""

from __future__ import annotations

import threading
import time
from pathlib import Path

from watchdog.events import FileCreatedEvent, FileSystemEventHandler
from watchdog.observers import Observer

from processor import MODELS, ROTEIROS, find_rbxms_for_pdf, pdf_stem_normalized, process_group

# ── Estado compartilhado ──────────────────────────────────────────────────────
_lock:    threading.Lock         = threading.Lock()
_pdfs:    dict[str, Path]        = {}   # pdf_stem → Path
_timers:  dict[str, threading.Timer] = {}   # pdf_stem → Timer de debounce

DEBOUNCE_SECS = 5  # aguarda 5s após último evento antes de disparar


# ── Lógica de paridade ────────────────────────────────────────────────────────

def _fire(pdf_stem: str) -> None:
    """Chamado após debounce: coleta todos os RBXMs e processa."""
    with _lock:
        pdf = _pdfs.pop(pdf_stem, None)
        _timers.pop(pdf_stem, None)

    if not pdf or not pdf.exists():
        return

    rbxms = find_rbxms_for_pdf(pdf)
    if not rbxms:
        print(f"[watch] Nenhum .rbxm encontrado para '{pdf.name}' — aguardando mais arquivos.")
        # Recoloca o PDF em espera
        with _lock:
            _pdfs[pdf_stem] = pdf
        return

    print(f"\n[watch] Disparando: {pdf.name} + {[r.name for r in rbxms]}")
    try:
        process_group(pdf, rbxms)
    except Exception as e:
        print(f"[watch] Erro ao processar '{pdf_stem}': {e}")


def _schedule(pdf_stem: str) -> None:
    """Cancela timer anterior e agenda um novo debounce para o pdf_stem."""
    with _lock:
        old = _timers.pop(pdf_stem, None)
        if old:
            old.cancel()
        t = threading.Timer(DEBOUNCE_SECS, _fire, args=(pdf_stem,))
        _timers[pdf_stem] = t
    t.start()


def _rbxm_to_pdf_stem(rbxm_path: Path) -> str | None:
    """
    Encontra o pdf_stem pendente que corresponde a este .rbxm.
    Retorna None se nenhum PDF está aguardando.
    """
    rstem = rbxm_path.stem.strip().lower()
    with _lock:
        for pdf_stem in _pdfs:
            if rstem == pdf_stem or rstem.startswith(pdf_stem + "-"):
                return pdf_stem
    # Também verifica se o PDF já existe em roteiros/ mesmo que não esteja em _pdfs
    for pdf in ROTEIROS.glob("*.pdf"):
        ps = pdf_stem_normalized(pdf)
        if rstem == ps or rstem.startswith(ps + "-"):
            with _lock:
                _pdfs[ps] = pdf
            return ps
    return None


# ── Handlers ──────────────────────────────────────────────────────────────────

class RoteiroPDFHandler(FileSystemEventHandler):
    def on_created(self, event: FileCreatedEvent) -> None:
        if not isinstance(event, FileCreatedEvent):
            return
        path = Path(event.src_path)
        if path.suffix.lower() != ".pdf":
            return
        time.sleep(1.5)
        print(f"[watch] PDF detectado: {path.name}")
        ps = pdf_stem_normalized(path)
        with _lock:
            _pdfs[ps] = path
        _schedule(ps)


class ModelRBXMHandler(FileSystemEventHandler):
    def on_created(self, event: FileCreatedEvent) -> None:
        if not isinstance(event, FileCreatedEvent):
            return
        path = Path(event.src_path)
        if path.suffix.lower() != ".rbxm":
            return
        time.sleep(1.5)
        print(f"[watch] RBXM detectado: {path.name}")
        ps = _rbxm_to_pdf_stem(path)
        if ps:
            _schedule(ps)
        else:
            print(f"[watch] Nenhum PDF correspondente para '{path.name}' — aguardando PDF.")


# ── Scan inicial ──────────────────────────────────────────────────────────────

def _scan_existing() -> None:
    """Processa pares já existentes nas pastas ao iniciar."""
    found_pdfs = list(ROTEIROS.glob("*.pdf"))
    if not found_pdfs:
        return

    for pdf in found_pdfs:
        ps = pdf_stem_normalized(pdf)
        rbxms = find_rbxms_for_pdf(pdf)
        if rbxms:
            print(f"[watch] Par existente: {pdf.name} + {[r.name for r in rbxms]}")
            with _lock:
                _pdfs[ps] = pdf
            _schedule(ps)
        else:
            print(f"[watch] PDF sem RBXM ainda: {pdf.name}")
            with _lock:
                _pdfs[ps] = pdf


# ── Ponto de entrada ──────────────────────────────────────────────────────────

if __name__ == "__main__":
    ROTEIROS.mkdir(exist_ok=True)
    MODELS.mkdir(exist_ok=True)

    print("Monitorando:")
    print(f"  PDFs  → {ROTEIROS}")
    print(f"  RBXMs → {MODELS}")
    print(f"  Debounce: {DEBOUNCE_SECS}s após o último arquivo detectado")
    print()
    print("Convenção de nomes:")
    print("  PDF:   meu-roteiro.pdf")
    print("  RBXMs: meu-roteiro.rbxm  |  meu-roteiro-layout.rbxm  |  meu-roteiro-vfx.rbxm")
    print()
    print("Ctrl+C para parar.\n")

    _scan_existing()

    observer = Observer()
    observer.schedule(RoteiroPDFHandler(), str(ROTEIROS), recursive=False)
    observer.schedule(ModelRBXMHandler(),  str(MODELS),   recursive=False)
    observer.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
        with _lock:
            for t in _timers.values():
                t.cancel()

    observer.join()
