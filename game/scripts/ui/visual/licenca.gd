class_name Licenca
extends RefCounted
## O que a Licença da Comunidade (v1.0, 28/06/2026) pede ao jogo (docs/60, ADR 0012): o
## título sem a marca, o selo na capa (tela de título) com ao menos 10% da largura, o aviso
## de conteúdo sensível, o aviso de IA junto do selo e a frase de conteúdo não oficial. Tudo
## num lugar só, para a tela de título, a tela Sobre e os testes lerem o mesmo texto.

## Título de trabalho: sem "Ordem Paranormal" (a marca não pode ir no título). Trocar aqui e
## em project.godot (config/name).
const TITULO := "Membrana"
const SUBTITULO := "Casos da Ordo Realitas"

const NAO_OFICIAL := "Conteúdo não oficial, publicado sob a Licença da Comunidade de Ordem Paranormal. " + \
	"Sem parceria, aprovação ou supervisão do titular dos direitos."
const AVISO_IA := "Contém material gerado por inteligência artificial"
const AVISO_CONTEUDO := "Este jogo é de terror. Tem violência, sangue, mortes de personagens, cultos, " + \
	"perda de sanidade, possessão e criaturas que perseguem o grupo. Não é para quem se sente mal com esses temas."
const AVISO_CONTEUDO_CURTO := "Conteúdo sensível: terror, violência, morte e perda de sanidade."
const LICENCA_URL := "ordemparanormal.com.br/licenca"
const VERSAO_LICENCA := "v1.0, de 28/06/2026"

## O selo oficial (baixado do site da licença). Sem o arquivo, a tela mostra o lugar reservado.
const SELO := "res://assets/licenca/selo.png"
## A licença pede o selo com ao menos 10% da largura da capa.
const FRACAO_SELO := 0.10


static func tem_selo() -> bool:
	return ResourceLoader.exists(SELO)


## O selo com a largura certa para uma tela de `largura_tela` px (≥ 10%, opaco). Sem o arquivo,
## um quadro tracejado do mesmo tamanho, para o lugar não ser ocupado por outra coisa.
static func selo(largura_tela: float) -> Control:
	var largura := ceilf(largura_tela * FRACAO_SELO) + 4.0
	if tem_selo():
		var t := TextureRect.new()
		t.texture = load(SELO)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var tam := (t.texture as Texture2D).get_size()
		t.custom_minimum_size = Vector2(largura, largura * tam.y / maxf(1.0, tam.x))
		t.name = "SeloLicenca"
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return t
	var p := PanelContainer.new()
	p.name = "SeloLicenca"
	p.custom_minimum_size = Vector2(largura, largura)
	p.add_theme_stylebox_override("panel", Tema.caixa(Color(0, 0, 0, 0.35), Tema.TEXTO_SUAVE, 1, 4, Vector2(6, 6)))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.text = "SELO DA\nLICENÇA"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", Tema.FONTE_P)
	l.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	p.add_child(l)
	p.tooltip_text = "O selo oficial da Licença da Comunidade vai aqui (%s)." % LICENCA_URL
	return p
