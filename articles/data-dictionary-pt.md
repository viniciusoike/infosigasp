# Dicionário de dados

Este artigo transcreve o dicionário de dados oficial do INFOSIGA-SP
(**v1.5, 16/06/2026**), publicado pelo DETRAN-SP, para as três bases que
[`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md)
retorna: `sinistros` (sinistros confirmados e notificações), `pessoas`
(vítimas) e `veiculos` (veículos). Os nomes dos campos, as descrições e
os códigos das categorias permanecem como constam na fonte. A
transcrição apenas normaliza quebras de linha, separadores de listas e
pequenos sinais de pontuação. `dictionary_infosiga(source = "official")`
abre o site de origem.

O artigo também está [disponível em
inglês](https://viniciusoike.github.io/infosigasp/articles/data-dictionary.md).

Três observações ajudam a consultar as tabelas.

- **Clique em uma linha** (ou na seta) para abrir o formato de
  armazenamento, a fonte do campo, a lista completa de valores
  permitidos e as observações.
- As colunas **Tipo** e **Nulos** descrevem o esquema da fonte, que nem
  sempre corresponde às classes que o pacote retorna.
  `processing = "raw"` retorna todos os campos como texto; `"typed"`
  converte as classes documentadas; e o modo padrão, `"clean"`, também
  trata valores ausentes, fatores e indicadores binários. Consulte
  [`?read_infosiga`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md)
  para conhecer o pipeline completo.
- No campo *Fonte*, **PC**, **PM** e **PRF** significam Polícia Civil,
  Polícia Militar e Polícia Rodoviária Federal. **DETRAN-SP** identifica
  os campos que o próprio sistema Infosiga deriva.

## Sinistros

Cada linha representa um sinistro confirmado ou uma notificação,
identificado por `id_sinistro` (48 variáveis).

## Pessoas

Cada linha representa uma vítima, identificada por `id_pessoa` e
vinculada às outras bases por `id_sinistro` e `id_veiculo` (30
variáveis).

## Veículos

Cada linha representa um veículo envolvido em um sinistro, identificado
por `id_sinistro` e `id_veiculo` (12 variáveis).

## Cobertura e ressalvas analíticas

A fonte publica uma série contínua desde 2015, mas seu escopo mudou ao
longo do tempo. Estas características pertencem aos dados publicados,
não ao processo de importação.

- **Os dados de 2015 a 2018 abrangem apenas sinistros fatais.** Os
  registros não fatais começam em 2019. Em tendências que incluam anos
  anteriores, restrinja `sinistros` a
  `tipo_registro == "SINISTRO FATAL"` ou `pessoas` a
  `gravidade_lesao == "FATAL"`. Caso contrário, inicie a série em 2019.
- **`tipo_registro` inclui notificações e sinistros confirmados.** Uma
  `"NOTIFICACAO"` é um evento informado que ainda não foi confirmado
  como sinistro. Filtre esse campo conforme a definição adotada na
  análise.
- **Os meses recentes são provisórios.** O DETRAN-SP reclassifica
  registros durante a validação, e os últimos meses de uma versão podem
  estar incompletos. Exclua as observações mais recentes ao compará-las
  com períodos consolidados.
- **`tempo_sinistro_obito` adota o limite de 30 dias.** As contagens de
  mortes, portanto, seguem a convenção de atribuir ao sinistro os óbitos
  em até 30 dias.
- **Os totais de veículos podem diferir entre tabelas.** A soma dos
  campos `qtd_*` de veículos nem sempre coincide com o número de linhas
  correspondentes em `veiculos`. Escolha uma medida e informe sua
  definição.
- **A cobertura de coordenadas varia por ano.** Os subconjuntos
  espaciais não formam uma amostra uniforme ao longo do tempo, sobretudo
  nos primeiros e nos últimos anos.
- **Alguns sinistros não têm pessoas ou veículos correspondentes.**
  Parta de `sinistros` com uma junção à esquerda quando a análise
  precisar preservar todos os sinistros.

Esses padrões descrevem as versões de 2026. Sua frequência pode mudar
quando o DETRAN-SP revisar os dados.

## Inconsistências conhecidas na fonte

Os arquivos PDF oficiais contêm algumas inconsistências internas. No
dicionário de `pessoas`, o formato de `ano_mes_sinistro` e
`ano_mes_obito` aparece como `mm/aaaa`, mas os intervalos permitidos e
os dados publicados usam `aaaa/mm`. Alguns intervalos indicam anos
posteriores a 2022, embora os arquivos correspondentes incluam 2022. As
observações de `ano_fab` e `ano_modelo` também apresentam as
desigualdades em ordem invertida. As tabelas acima preservam a redação
oficial. As especificações de tipo do pacote seguem os valores dos
arquivos de dados; os identificadores e `numero_logradouro` permanecem
como texto para evitar perda de informação.

## Fonte

DETRAN-SP, *Dicionário de dados* v1.5 (16/06/2026), distribuído com os
dados abertos do INFOSIGA-SP em <https://infosiga.detran.sp.gov.br/>.
`dictionary_infosiga(source = "official")` abre o site de origem.

``` r

infosigasp::dictionary_infosiga(source = "official")
```
