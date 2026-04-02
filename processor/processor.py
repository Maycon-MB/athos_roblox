"""
Processador de roteiros — Athos Roblox
Domínio: PDF + N RBXMs → Entrega completa pronta para QA no Studio.

Responsabilidades (SRP):
  - extract_pdf        : extrai texto e hiperlinks do PDF
  - build_roteiro_md   : gera ROTEIRO.md com contexto do roteiro
  - build_project_json : gera default.project.json com Environment_Dirty multi-rbxm
  - copy_engine        : copia engine-template/ para a pasta da entrega
  - rojo_build         : chama rojo build para gerar game_ready.rbxl
  - process_group      : orquestra tudo dado um PDF + lista de RBXMs
"""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

import pdfplumber

ROOT        = Path(__file__).parent.parent
ROTEIROS    = ROOT / "roteiros"
MODELS      = ROOT / "models_to_process"
ENTREGAS    = ROOT / "entregas"
ENGINE_TMPL = ROOT / "engine-template" / "src"
ROJO_EXE    = ROOT / "rojo.exe"


# ── Domínio ────────────────────────────────────────────────────────────────────

def extract_pdf(pdf_path: Path) -> dict:
    """Extrai texto e todos os hiperlinks embutidos do PDF."""
    texto_paginas: list[str] = []
    links: list[str] = []

    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            content = page.extract_text()
            if content:
                texto_paginas.append(content)

            if hasattr(page, "hyperlinks"):
                for link in page.hyperlinks:
                    uri = link.get("uri", "")
                    if uri and uri not in links:
                        links.append(uri)

            try:
                annots = page.page_obj.get("/Annots")
                if annots:
                    for annot in annots:
                        obj = annot.get_object()
                        action = obj.get("/A", {})
                        uri = action.get("/URI", b"")
                        if isinstance(uri, bytes):
                            uri = uri.decode("utf-8", errors="ignore")
                        if uri and uri not in links:
                            links.append(uri)
            except Exception:
                pass

    return {
        "titulo": pdf_path.stem,
        "texto": "\n".join(texto_paginas),
        "links": links,
    }


def extract_place_id(links: list[str]) -> tuple[str, str]:
    """Extrai PlaceId e URL do jogo base a partir dos links do PDF."""
    share_links: list[str] = []
    for link in links:
        match = re.search(r"roblox\.com(?:/\w{2})?/games/(\d+)", link)
        if match:
            return match.group(1), link
        if "roblox.com/share" in link and "ExperienceDetails" in link:
            share_links.append(link)

    if share_links:
        return "", share_links[0]
    return "", ""


def slugify(text: str) -> str:
    text = text.lower()
    for src, dst in [("á","a"),("à","a"),("ã","a"),("â","a"),("é","e"),("ê","e"),
                     ("í","i"),("ó","o"),("õ","o"),("ô","o"),("ú","u"),("ç","c")]:
        text = text.replace(src, dst)
    text = re.sub(r"[^a-z0-9]+", "-", text)
    return text.strip("-")[:80]


def rbxm_key(rbxm_path: Path) -> str:
    """Gera chave segura para usar no project.json a partir do stem do arquivo."""
    stem = re.sub(r"[^a-z0-9]+", "_", rbxm_path.stem.lower()).strip("_")
    return stem or "model"


# ── Matching de prefixo ────────────────────────────────────────────────────────

def pdf_stem_normalized(pdf_path: Path) -> str:
    return pdf_path.stem.strip().lower()


def rbxm_matches_pdf(rbxm_path: Path, pdf_stem: str) -> bool:
    """
    Um .rbxm pertence a um PDF se seu stem for idêntico ao do PDF
    ou começar com '<pdf_stem>-' (convenção de sufixo).
    Ex: PDF 'escape-tsunami' → aceita 'escape-tsunami.rbxm'
        e 'escape-tsunami-vfx.rbxm', 'escape-tsunami-layout.rbxm', etc.
    """
    rstem = rbxm_path.stem.strip().lower()
    return rstem == pdf_stem or rstem.startswith(pdf_stem + "-")


def find_rbxms_for_pdf(pdf_path: Path) -> list[Path]:
    """Retorna todos os .rbxm em MODELS que correspondem ao PDF."""
    stem = pdf_stem_normalized(pdf_path)
    return sorted(
        [f for f in MODELS.glob("*.rbxm") if rbxm_matches_pdf(f, stem)],
        key=lambda p: p.stem.lower(),
    )


# ── Geração de arquivos ────────────────────────────────────────────────────────

def build_roteiro_md(pdf: dict, place_id: str, link_jogo: str, rbxm_names: list[str]) -> str:
    date_str = datetime.now().strftime("%Y-%m-%d")
    lines = [
        f"# Roteiro — {pdf['titulo']}",
        "",
        f"**Data:** {date_str}",
        f"**PlaceId:** `{place_id}`" if place_id else "**PlaceId:** _usar link de share abaixo_",
        f"**Link:** {link_jogo}" if link_jogo else "**Link:** _não encontrado no PDF_",
        "**Prazo:** 2 dias",
        "",
        "---",
        "",
        "## Modelos injetados (Environment_Dirty)",
        "",
    ]
    for name in rbxm_names:
        lines.append(f"- `{name}`")
    lines += [
        "",
        "---",
        "",
        "## Links extraídos do PDF",
        "",
    ]
    if pdf["links"]:
        for link in pdf["links"]:
            lines.append(f"- {link}")
    else:
        lines.append("_Nenhum link encontrado_")

    lines += [
        "",
        "---",
        "",
        "## Conteúdo completo do roteiro",
        "",
        pdf["texto"],
    ]
    return "\n".join(lines)


def build_project_json(name: str, env_entries: dict[str, str]) -> dict:
    """
    Gera default.project.json com pasta Environment_Dirty contendo N modelos.
    env_entries: {chave_rojo: path_relativo_rbxm}
    """
    environment_dirty: dict = {"$className": "Folder"}
    for key, path in env_entries.items():
        environment_dirty[key] = {"$path": path}

    return {
        "name": name,
        "tree": {
            "$className": "DataModel",
            "Workspace": {
                "$className": "Workspace",
                "Environment_Dirty": environment_dirty,
            },
            "ReplicatedStorage": {
                "$className": "ReplicatedStorage",
                "Shared": {
                    "$className": "Folder",
                    "Settings": {"$path": "src/shared/Settings.lua"},
                    "Remotes":  {"$path": "src/shared/Remotes.lua"},
                },
            },
            "ServerScriptService": {
                "$className": "ServerScriptService",
                "WipeEnvironment": {"$path": "src/server/WipeEnvironment.server.lua"},
                "CoreEngine":      {"$path": "src/server/CoreEngine.server.lua"},
                "Engine": {
                    "$className": "Folder",
                    "MapTagger":      {"$path": "src/server/Engine/MapTagger.lua"},
                    "PlayerData":     {"$path": "src/server/Engine/PlayerData.lua"},
                    "WaveSystem":     {"$path": "src/server/Engine/WaveSystem.lua"},
                    "BrainrotSystem": {"$path": "src/server/Engine/BrainrotSystem.lua"},
                    "JumpSystem":     {"$path": "src/server/Engine/JumpSystem.lua"},
                    "AdminSystem":    {"$path": "src/server/Engine/AdminSystem.lua"},
                    "MobSystem":      {"$path": "src/server/Engine/MobSystem.lua"},
                },
            },
            "StarterPlayer": {
                "$className": "StarterPlayer",
                "StarterPlayerScripts": {
                    "$className": "StarterPlayerScripts",
                    "CoreClient": {"$path": "src/client/CoreClient.client.lua"},
                    "UI": {
                        "$className": "Folder",
                        "StatusBar":        {"$path": "src/client/UI/StatusBar.lua"},
                        "JumpShop":         {"$path": "src/client/UI/JumpShop.lua"},
                        "WaveAlert":        {"$path": "src/client/UI/WaveAlert.lua"},
                        "WaveMachinePanel": {"$path": "src/client/UI/WaveMachinePanel.lua"},
                        "ProgressPanel":    {"$path": "src/client/UI/ProgressPanel.lua"},
                        "AdminPanel":       {"$path": "src/client/UI/AdminPanel.lua"},
                    },
                },
            },
        },
    }


SETTINGS_STUB = """\
--!strict
------------------------------------------------------------------------
-- SETTINGS.LUA — ÚNICO ARQUIVO QUE VOCÊ EDITA POR ROTEIRO
-- Leia o ROTEIRO.md e preencha via Claude Code no terminal.
-- Os valores abaixo são defaults seguros para o Engine não crashar.
-- Substitua tudo conforme o roteiro.
------------------------------------------------------------------------
local S = {}

-- ── TAGS ─────────────────────────────────────────────────────────────
S.TAG_MAP = {
    Tsunami     = { "Water", "Wave", "Tsunami", "Ocean" },
    SafeZone    = { "SafeZone", "Shelter" },
    WaveMachine = { "WaveMachine" },
    FuseMachine = { "FuseMachine" },
    CrackWall   = { "CrackWall", "SecretWall" },
}

-- ── TSUNAMI ───────────────────────────────────────────────────────────
S.WAVE = {
    INTERVAL    = 30,
    SPEED       = 18,
    SPEED_MAX   = 60,
    HOLD_TIME   = 2,
    RECEDE_MULT = 2,
    TAG_WATER   = "TsunamiWater",
    TAG_START   = "StartPoint",
    TAG_END     = "EndPoint",
    TAG_SAFEZONE= "SafeZone",
}

-- ── RARIDADES ─────────────────────────────────────────────────────────
S.RARITIES = {
    [1] = { name = "Common",    color = Color3.fromRGB(180,180,180) },
    [2] = { name = "Uncommon",  color = Color3.fromRGB( 80,200, 80) },
    [3] = { name = "Rare",      color = Color3.fromRGB( 60,120,220) },
    [4] = { name = "Epic",      color = Color3.fromRGB(160, 60,220) },
    [5] = { name = "Legendary", color = Color3.fromRGB(255,200,  0) },
    [6] = { name = "Metata",    color = Color3.fromRGB(255, 80,  0) },
    [7] = { name = "Infinity",  color = Color3.fromRGB(255, 20,147) },
}
S.SPAWN_WEIGHTS = { 60, 25, 10, 4, 1, 0.1, 0.02 }

-- ── BRAINROTS ─────────────────────────────────────────────────────────
S.BRAINROT_ZONE = { Z_MIN=-180, Z_MAX=180, X_RANGE=16, Y=1, MAX=12, RATE=3 }
S.BRAINROTS = {}  -- TODO: preencher com base no roteiro

-- ── PULOS ────────────────────────────────────────────────────────────
S.JUMPS = {}  -- TODO: preencher com base no roteiro

-- ── BASE ──────────────────────────────────────────────────────────────
S.BASE = { SLOTS_DEFAULT = 4, SLOTS_MAX = 12 }

-- ── SPAWN ─────────────────────────────────────────────────────────────
S.SPAWN = { POSITION = Vector3.new(0, 5, 0) }

return S
"""


def copy_engine(entrega_dir: Path) -> None:
    """Copia engine-template/src/ para entrega/src/. Settings.lua sempre gerado como stub."""
    dest = entrega_dir / "src"
    if ENGINE_TMPL.exists():
        shutil.copytree(ENGINE_TMPL, dest, dirs_exist_ok=True)
    else:
        for d in ["server/Engine", "client/UI", "shared"]:
            (dest / d).mkdir(parents=True, exist_ok=True)

    # Settings.lua é sempre o stub — nunca copiado do template
    (dest / "shared" / "Settings.lua").write_text(SETTINGS_STUB, encoding="utf-8")


def rojo_build(entrega_dir: Path) -> bool:
    """Executa rojo build e gera game_ready.rbxl. Retorna True se bem-sucedido."""
    if not ROJO_EXE.exists():
        print("  [WARN] rojo.exe não encontrado — game_ready.rbxl não gerado.")
        return False

    result = subprocess.run(
        [
            str(ROJO_EXE.resolve()),
            "build",
            str((entrega_dir / "default.project.json").resolve()),
            "--output",
            str((entrega_dir / "game_ready.rbxl").resolve()),
        ],
        cwd=str(entrega_dir.resolve()),
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"  [WARN] rojo build falhou:\n{result.stderr.strip()}")
        return False
    print("  game_ready.rbxl gerado!")
    return True


def git_push(folder_name: str) -> None:
    """Faz commit e push da entrega para o GitHub."""
    try:
        subprocess.run(["git", "add", f"entregas/{folder_name}"], cwd=str(ROOT), check=True, capture_output=True)
        subprocess.run(
            ["git", "commit", "-m", f"feat: entrega {folder_name}"],
            cwd=str(ROOT), check=True, capture_output=True,
        )
        result = subprocess.run(["git", "push"], cwd=str(ROOT), capture_output=True, text=True)
        if result.returncode == 0:
            print("  GitHub: push OK")
        else:
            print(f"  [WARN] git push falhou: {result.stderr.strip()}")
    except subprocess.CalledProcessError as e:
        print(f"  [WARN] git erro: {e}")


# ── Orquestrador principal ────────────────────────────────────────────────────

def process_group(pdf_path: Path, rbxm_paths: list[Path]) -> None:
    """Processa um PDF + N RBXMs e cria a entrega completa."""
    print(f"\n[1/6] Lendo PDF: {pdf_path.name}")
    pdf = extract_pdf(pdf_path)

    print(f"[2/6] Extraindo links ({len(pdf['links'])} encontrados)")
    place_id, link_jogo = extract_place_id(pdf["links"])
    if place_id:
        print(f"      PlaceId: {place_id}")
    else:
        print("      PlaceId não encontrado — adicione manualmente no ROTEIRO.md")

    print(f"[3/6] Criando estrutura da entrega ({len(rbxm_paths)} modelo(s))")
    date_str = datetime.now().strftime("%Y-%m-%d")
    titulo = next((l.strip() for l in pdf["texto"].splitlines() if l.strip()), pdf["titulo"])
    stopwords = {"do","da","de","mas","posso","no","na","e","o","a","os","as","um","uma"}
    palavras = [p for p in re.split(r"\W+", titulo.lower()) if p and p not in stopwords]
    slug = slugify("-".join(palavras[:4]))
    folder_name = f"{date_str}_{slug}"
    entrega_dir = ENTREGAS / folder_name
    entrega_dir.mkdir(parents=True, exist_ok=True)
    (entrega_dir / "roteiros_originais").mkdir(exist_ok=True)

    print("[4/6] Copiando modelos e Engine")
    # Copia cada .rbxm para a entrega com nome seguro e monta env_entries
    env_entries: dict[str, str] = {}
    for rbxm in rbxm_paths:
        key  = rbxm_key(rbxm)
        dest = entrega_dir / f"{key}.rbxm"
        shutil.copy2(rbxm, dest)
        env_entries[key] = f"{key}.rbxm"
        print(f"      + {rbxm.name} -> {key}.rbxm")
    copy_engine(entrega_dir)

    print("[5/6] Gerando ROTEIRO.md e default.project.json")
    (entrega_dir / "ROTEIRO.md").write_text(
        build_roteiro_md(pdf, place_id, link_jogo, [r.name for r in rbxm_paths]),
        encoding="utf-8",
    )
    project_name = "Athos" + "".join(w.capitalize() for w in slug.split("-")[:3])
    (entrega_dir / "default.project.json").write_text(
        json.dumps(build_project_json(project_name, env_entries), indent="\t", ensure_ascii=False),
        encoding="utf-8",
    )

    print("[6/7] Rodando rojo build")
    built = rojo_build(entrega_dir)

    # Arquiva originais (move PDF e todos os RBXMs)
    dest_pdf = entrega_dir / "roteiros_originais" / pdf_path.name
    if dest_pdf.exists(): dest_pdf.unlink()
    pdf_path.rename(dest_pdf)
    for rbxm in rbxm_paths:
        dest_rbxm = entrega_dir / "roteiros_originais" / rbxm.name
        if dest_rbxm.exists(): dest_rbxm.unlink()
        rbxm.rename(dest_rbxm)

    print("[7/7] Subindo para o GitHub")
    git_push(folder_name)

    print(f"\nEntrega criada: entregas/{folder_name}/")
    print(f"  Modelos em Workspace > Environment_Dirty (limpos pelo WipeEnvironment)")
    print(f"  Para editar ao vivo no Studio (sem reabrir):")
    print(f"    cd entregas/{folder_name}")
    print(f"    ..\\..\\rojo.exe serve default.project.json")
    print(f"  Depois conecte o plugin Rojo no Studio.")


# ── CLI direto ────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    # Uso: python processor.py <roteiro.pdf> [modelo1.rbxm modelo2.rbxm ...]
    # Se apenas o PDF for passado, procura RBXMs automaticamente em models_to_process/
    if len(sys.argv) < 2:
        print("Uso: python processor.py <roteiro.pdf> [modelo.rbxm ...]")
        print("     Ou use watch.py para processamento automático.")
        sys.exit(1)

    pdf = Path(sys.argv[1])
    if not pdf.exists():
        print(f"PDF não encontrado: {pdf}"); sys.exit(1)

    if len(sys.argv) > 2:
        rbxms = [Path(a) for a in sys.argv[2:]]
        missing = [r for r in rbxms if not r.exists()]
        if missing:
            print(f"RBXM(s) não encontrado(s): {', '.join(str(m) for m in missing)}")
            sys.exit(1)
    else:
        rbxms = find_rbxms_for_pdf(pdf)
        if not rbxms:
            print(f"Nenhum .rbxm encontrado em {MODELS} para o PDF '{pdf.stem}'")
            sys.exit(1)
        print(f"RBXMs detectados automaticamente: {[r.name for r in rbxms]}")

    process_group(pdf, rbxms)
