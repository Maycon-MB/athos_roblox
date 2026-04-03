# Valores Calibrados — NÃO REVERTER

| Parâmetro | Valor | Motivo |
|---|---|---|
| `pe.LightEmission` | `0.18` | 0.85 inundava o mapa de luz cyan |
| Portal PointLight range | `16` | 35+ causava overflow de luz |
| VIP Portal PointLight range | `18` | idem |
| Waterfall PointLight range | `12` | idem |
| Particle rate portais | `6` | mais que isso fica poluído |
| Bloom Intensity | `0.35` | suave, sem machucar os olhos |
| Bloom Threshold | `0.92` | só realça neons fortes |
| `Lighting.Technology` | **NÃO SETAR** | RobloxScript sem permissão — erro fatal |
| `ShadowIntensity` em PointLight | **NÃO USAR** | propriedade inexistente — erro fatal |

## Erros históricos resolvidos
- `Lighting.Technology` → remover; RobloxScript não tem permissão
- `ShadowIntensity is not a valid member of PointLight` → inexistente
- Fonte aparecia como cruz (+) → substituir 4 bordas por base sólida
- Portais girando como porta → `rotateZ` em vez de `rotateY`
- Mapa inundado cyan → calibrar LightEmission (0.18) e ranges (12-18)
- Hub dentro do spawn → mover centro de (-70,-70) para (0,0)
- Sound IDs HTTP 403 → rbxasset:// para fonte/portais; música falha silenciosa
