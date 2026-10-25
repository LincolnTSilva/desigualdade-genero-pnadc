# Roda depois de cada renderização (post-render no _quarto.yml).
# Copia o relatório e o Dia 1 para a pasta downloads/ do site, para que os
# links "Baixar o relatório" e "Baixar o Dia 1" entreguem o arquivo .qmd, e
# não a página .html.

pasta_site <- Sys.getenv('QUARTO_PROJECT_OUTPUT_DIR', '_site')
pasta_downloads <- file.path(pasta_site, 'downloads')

dir.create(pasta_downloads, showWarnings = FALSE, recursive = TRUE)
file.copy('relatorio.qmd', pasta_downloads, overwrite = TRUE)

# O Dia 1 vai como está na página, sem os comentários internos que marcam
# as partes copiadas do relatório (<!-- dia: ... --> e <!-- /dia -->)
dia1 <- readLines('dia1.qmd', encoding = 'UTF-8')
comentario <- grepl('^<!-- (dia: |/dia -->|Página gerada por)', dia1)
writeLines(dia1[!comentario], file.path(pasta_downloads, 'dia1.qmd'), useBytes = TRUE)
