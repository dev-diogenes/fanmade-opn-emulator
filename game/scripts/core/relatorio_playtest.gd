class_name RelatorioPlaytest
extends RefCounted
## Relatório do playtest (docs/78): um .txt que o testador gera na Pausa e manda de volta.
## Junta o que o jogo já guarda: as estatísticas do tutorial, um resumo da carreira, o relatório
## da última missão e o fim do registro da missão em andamento. Nada sai do computador sozinho
## (sem rede, LI4); os nomes são dos agentes do jogo, não de pessoas.

const PASTA := "user://relatorios"
const LINHAS_DO_REGISTRO := 120


static func texto(carreira: Carreira, agora: Dictionary = {}) -> String:
	var t := agora if not agora.is_empty() else Time.get_datetime_dict_from_system()
	var l: PackedStringArray = []
	l.append("RELATÓRIO DO PLAYTEST — %s" % String(ProjectSettings.get_setting("application/config/name", "Membrana")))
	l.append("Gerado em %04d-%02d-%02d %02d:%02d" % [int(t.year), int(t.month), int(t.day), int(t.hour), int(t.minute)])
	l.append("Sistema: %s | Godot %s | Tela %s" % [OS.get_name(), Engine.get_version_info().string, str(DisplayServer.window_get_size()) if DisplayServer.get_name() != "headless" else "headless"])
	l.append("")
	l.append("== Tutorial ==")
	var est := Preferencias.estatisticas()
	if est.is_empty():
		l.append("(sem registros)")
	for tela in est:
		var e: Dictionary = est[tela]
		l.append("%s: iniciado %d, concluído %d, pulado %d%s" % [tela, int(e.get("inicio", 0)), int(e.get("concluido", 0)), int(e.get("pulado", 0)),
			(" (pulou no passo %s)" % JSON.stringify(e.pulou_no_passo)) if e.has("pulou_no_passo") else ""])
	l.append("")
	l.append("== Carreira ==")
	if carreira == null:
		l.append("(sem carreira)")
		return "\n".join(l) + "\n"
	l.append("Missões concluídas: %d | Agentes: %d | No memorial: %d | Sigilos na tabela: %d/26" % [carreira.missoes_concluidas,
		carreira.roster.size(), carreira.memorial.size(), carreira.sigilos_conhecidos.size()])
	for a in carreira.roster:
		l.append("- %s: %s, NEX %d%%, PV %d/%d, SAN %d/%d" % [a.nome, a.classe_id, a.nex, a.pv, a.pv_maximo, a.san, a.san_maximo])
	var rel: Dictionary = carreira.ultimo_relatorio
	if not rel.is_empty():
		l.append("")
		l.append("== Última missão ==")
		l.append("Vitória: %s | Caso solucionado: %s | Turnos: %s | Membrana: %s | PP: %s" % [str(rel.get("vitoria", "?")), str(rel.get("solucionado", "?")),
			str(rel.get("turnos", "?")), str(rel.get("membrana", "?")), str(rel.get("pp", "?"))])
		for linha in rel.get("detalhes_pp", []):
			l.append("  " + String(linha))
	var m := carreira.missao
	if m != null:
		l.append("")
		l.append("== Missão em andamento ==")
		l.append("Turno do mundo: %d | Membrana: %d | Encerrada: %s" % [m.turno_mundo, m.membrana.valor, str(m.encerrada)])
		l.append("-- Registro (últimas %d linhas) --" % LINHAS_DO_REGISTRO)
		for linha in m.historico.slice(maxi(0, m.historico.size() - LINHAS_DO_REGISTRO)):
			l.append(_sem_bbcode(linha))
	return "\n".join(l) + "\n"


## Grava o relatório e devolve o caminho no disco ("" se falhar).
static func gerar(carreira: Carreira) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA))
	var t := Time.get_datetime_dict_from_system()
	var caminho := "%s/playtest_%04d%02d%02d_%02d%02d%02d.txt" % [PASTA, int(t.year), int(t.month), int(t.day), int(t.hour), int(t.minute), int(t.second)]
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(texto(carreira, t))
	f.close()
	return ProjectSettings.globalize_path(caminho)


static func _sem_bbcode(s: String) -> String:
	var re := RegEx.create_from_string("\\[/?[a-z_]+(=[^\\]]*)?\\]")
	return re.sub(s, "", true)
