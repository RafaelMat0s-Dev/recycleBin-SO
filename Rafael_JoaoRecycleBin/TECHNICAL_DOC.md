
- System ASCII and Architecture Diagram

[Ver Imagem](./screenshots/Architecture.jpg)

- Metadata File explanation
The metadata.csv file is the central catalog for managing deleted files.
Each record represents one deleted file and contains the following attributes:

| **Field**       | **Description**                                           | **Example**                      |
| --------------- | --------------------------------------------------------- | -------------------------------- |
| `ID`            | Unique identifier (integer or UUID) for each deleted file | `7319d932-5860-4626-b165-2b5d5b860adb`                            |
| `ORIGINAL_NAME` | The original filename before deletion                     | `document.txt`                   |
| `ORIGINAL_PATH` | Full path to where the file was deleted from              | `/home/rafael/docs/document.txt` |
| `DELETION_DATE` | Timestamp when the file was deleted                       | `2025-10-30 18:30:45`            |
| `FILE_SIZE`     | File size in bytes                                        | `2048`                           |
| `FILE_TYPE`     | MIME type or file extension                               | `text/plain`                     |
| `PERMISSIONS`   | Original permissions with their numbers                   | `777`                      |
| `OWNER`         | Username of the file owner                                | `rafael`                         |


# Function - initialize_recyclebin()

- Context Diagram & Diagram
[Ver Imagem](./screenshots/Initialize_recycle.jpg)


- Function description

initialize_recyclebin() -> Initializes the recycle bin environment in the user’s home directory.
                        -> Creates ~/.recycle_bin structure and its supporting files.
                        -> Logs errors/warnings when creation or validation fails.


- Design decisions and rationale

A função initialize_recyclebin() foi desenhada para ser segura, simples e fiável.
O diretório do recycle bin fica em $HOME/.recycle_bin para garantir que cada utilizador tem o seu próprio espaço, sem problemas de permissões. Foram usados ficheiros de texto simples (CSV e config) para facilitar a leitura, edição e integração com comandos shell, evitando dependências externas.
O ficheiro de configuração permite ajustar parâmetros sem alterar o código, e o log (recyclebin.log) assegura que sempre que se pretende fazer o debug de todas as ações pode-se consultar esse ficheiro para ver o que aconteceu
O script evita sobrescrever dados existentes, validando o ambiente e todos os ficheiros antes de os criar. Assim, garante-se que a inicialização é sempre previsível, segura e sem perdas de dados.

- Algorithm explanation

Algoritmo valida primeiro se o $HOME existe e é válido.
Depois verifica se o recycle bin já existe — se sim, emite um aviso e termina. Caso contrário, cria a estrutura de diretórios, o ficheiro metadata.csv com cabeçalho, o ficheiro config com valores por defeito e o log.
Em seguida, lê e valida os valores da configuração e confirma que o log é gravável. Por fim, escreve no log que a inicialização foi concluída com sucesso.


# Function - delete_file()

- Data Flow Diagram
[Ver Imagem](./screenshots/delete_file.jpg)

- Descrição da Função

A função delete_file() é responsável por simular a eliminação de ficheiros e diretórios de forma segura e reversível.
Em vez de apagar permanentemente, move os itens para o diretório do recycle bin (~/.recycle_bin/files) e regista toda a informação relevante no ficheiro metadata.csv.
Durante o processo, valida se o recycle bin está inicializado, verifica permissões, espaço em disco e impede a eliminação do próprio bin.
Cada operação é registada num log, permitindo rastrear todas as ações executadas e recuperar ficheiros mais tarde, se necessário.

- Decisões de Design e Programação

A função delete_file() é responsável por simular a eliminação de ficheiros e diretórios de forma segura e reversível.
Em vez de apagar permanentemente, move os itens para o diretório do recycle bin (~/.recycle_bin/files) e regista toda a informação relevante no ficheiro metadata.csv.
Durante o processo, valida se o recycle bin está inicializado, verifica permissões, espaço em disco e impede a eliminação do próprio bin.
Cada operação é registada num log, permitindo rastrear todas as ações executadas e recuperar ficheiros mais tarde, se necessário.

- Explicação do algoritmo
Como este é um dos maiores algoritmos a explicação é feita na foto de controlo de fluxo de dados [Ver Aqui](./screenshots/)

# Function - restore_file()

- Data Flow Diagram
[Ver Imagem](./screenshots/restoreFile.jpg)

- Descrição da Função

A função restore_file() permite recuperar ficheiros eliminados do recycle bin para o seu local original, garantindo segurança e consistência.
Recebe como argumento o ID ou nome do ficheiro, valida a existência nos metadados, recria o diretório original se necessário e move o ficheiro de volta, pedindo confirmação ao utilizador caso já exista um ficheiro com o mesmo nome.
Todos os eventos são registados no log para auditoria.

- Decisões de Design e Programação

O utilizador pode restaurar ficheiros tanto pelo UUID/ID como pelo nome original, tornando a função mais prática e tolerante a diferentes usos.
Antes de restaurar, verifica se o ficheiro e metadados existem, se o diretório original está disponível e se há conflitos de nomes — garantindo integridade do sistema.
Em caso de conflito, o utilizador escolhe entre sobrescrever, renomear ou cancelar, prevenindo perda acidental de dados.
Todas as ações (sucesso, falha ou cancelamento) são escritas no ficheiro de log, reforçando a transparência e permitindo depuração.
Após o restauro, a entrada correspondente é eliminada do metadata.csv para manter o ficheiro coerente.

- Explicação  do algoritmo
Como este é um dos maiores algoritmos a explicação é feita na foto de controlo de fluxo de dados [Ver Aqui](./screenshots/)

# Function - preview_file()

- Data Flow Diagram
[Ver Imagem](./screenshots/previewFile.jpg)

- Descrição da Função
A função preview_file() permite ao utilizador visualizar informação sobre um ficheiro eliminado sem o restaurar. O seu objetivo é oferecer uma forma rápida de confirmar o conteúdo e tipo do ficheiro antes de decidir restaurá-lo ou eliminá-lo permanentemente.

- Decisões de Design e Programação
Foi desenhada para ser segura e não intrusiva — nunca modifica o estado do sistema, apenas lê metadados e, no caso de ficheiros de texto, mostra as primeiras 10 linhas para evitar sobrecarregar o terminal.
A decisão de usar file e head baseia-se na simplicidade e universalidade destes comandos.
O metadata.csv é usado como fonte central para obter o nome original, data e tamanho, garantindo consistência e rastreabilidade.
O log documenta tanto o sucesso como falhas, mantendo histórico completo das ações.

- Explicação  do algoritmo
Inicialização de variáveis, aonde define os caminhos principais do recycle bin e lê o argumento (ID do ficheiro).
Validação do argumento onde se o ID não for fornecido, é mostrado um erro e o processo termina.
Procura no metadata.csv e Localiza a linha correspondente ao ID para obter todos os dados do ficheiro.
Verificação da existência do ficheiro e Confirma se o ficheiro físico ainda está presente em files/.
Deteção do tipo de ficheiro usando o comando file para determinar o MIME type.
Apresentação da informação mostrando nome, tipo, tamanho e data de eliminação.
Se for um ficheiro de texto, exibe as primeiras 10 linhas.
Se for binário, mostra apenas detalhes técnicos.
Registo no log: Dependendo do resultado, escreve o evento como sucesso, informação ou falha.


# Function - list_recycle()
[Ver Imagem](./screenshots/list_file.jpg)

- Descrição da Função

A função list_recycled() permite ao utilizador visualizar o conteúdo do recycle bin, fornecendo tanto uma visão resumida quanto uma detalhada dos ficheiros eliminados.
O propósito é dar transparência e controlo sobre os ficheiros armazenados, permitindo que o utilizador saiba o que pode restaurar ou remover definitivamente.

- Decisões de Design e Programação

Opção detalhada (--detailed) oferece flexibilidade para ver informações completas (ID, nome, caminho original, tipo, permissões, dono).
Formatação clara e legível com tabela resumida ou detalhada, incluindo a conversão de tamanhos para formato humano (numfmt).
Cálculo de totais Mostrando contagem total e tamanho cumulativo, fornecendo visão geral rápida.
Validação e log,sendo que se o recycle bin estiver vazio, comunica ao utilizador e regista no log, mantendo rastreabilidade.

- Explicação  do algoritmo

A função list_recycled() lê o ficheiro de metadados do recycle bin (metadata.csv) e apresenta ao utilizador uma lista dos ficheiros eliminados, podendo exibir uma visão resumida ou detalhada.
O algoritmo começa por inicializar os caminhos do recycle bin e verificar se foi passada a opção --detailed. Se o ficheiro de metadados estiver vazio, informa que o recycle bin está vazio e regista a ação no log.
Em seguida, percorre cada linha do metadata.csv, ignorando cabeçalhos ou entradas inválidas, e acumula a contagem de ficheiros e o tamanho total. Cada tamanho é convertido para um formato legível, se disponível.
Para cada ficheiro, mostra:
Resumo: ID parcial, nome, data e tamanho.
Detalhado: ID completo, nome, caminho original, data de eliminação, tamanho, tipo, permissões e dono.
No final, imprime o total de itens e o tamanho acumulado do recycle bin, registando a operação no log.

# Function - empty_recycle()
[Ver Imagem](./screenshots/EmptyFileDiagram.png)

- Descrição da Função 
A função empty_recycle() permite eliminar permanentemente ficheiros do recycle bin onde é aceite como argumento da função o id único, garantindo segurança para eliminar o ficheiro correto.
Recebe como argumentos um ou vários IDs únicos de ficheiro e usa o metadata file para obter o nome do ficheiro e assim eliminá-lo permanentemente da recycle bin. Tem também um controlo de segurança, onde pergunta ao utilizador se quer ou não eliminar os ficheiros

- Decisões de Design e Programação
Aceita apenas IDs de ficheiro, para garantir que apaga o ficheiro certo
Opção forçada --force que permite eliminar os ficheiro sem precisar de perguntar ao utilizador e também, tem a palavra all ou simplesmente não escrever nada e ele esvazia a recycle na totalidade. 

- Explicação do algoritmo

A função empty_recycle() é responsável por eliminar permanentemente ficheiro da recycle bin pelo ID, de forma a tornar mais seguro.
Esta começa por verificar se a recycle está vazia, pois assim garante uma melhor eficiência. Se a recycle estiver vazia, retorna um erro dizendo que a recycle já está vazia
De seguida verifica se algum dos argumentos é a flag "--force", que tem como objetivo pular a confirmação do utilizador. Caso não tenha faz a pergunta se pretende ou não prosseguir. Caso contrário a confirmação é ignorada e o argumento "--force" é eliminado
Em seguida verifica mais uma vez os argumentos, verificando se existe algum argumento ou se existe a palavra "all". Caso exista o programa procede com a eliminação de todos os ficheiros da recycle e limpa todo o ficheiro da metadata.bd, deixando apenas o cabeçalho.
Caso negativo, o programa corre argumento a argumento e caso algum argumento exista no metadata.bd, ele procede à eliminação recursiva e forçada(rm -rf) do ficheiro, e remove o registo do ficheiro da metadata. Cada ficheiro que ele não encontre é dado um erro que depois será registado no log 
Por fim, é feito o registo no log dos erros(caso haja) e dos ficheiros que conseguiu eliminar(caso tenha conseguido eliminar todos, regista no log a operação apenas) e o retorno (0 em caso de sucesso e 1 caso haja algum erro)

# Function - search_recycle()
[Ver Imagem](screenshots/SearchFileDiagram.png)

- Descrição da Função
A função search_recycle permite ao utilizador pesquisar por ficheiros dentro da recycle. O seu objetivo é facilitar ao utilizador a procura por algum ficheiro específico, dando informações extra para ajudar a decidir se quer ou não eliminar permanentemente ou restaurar o ficheiro

- Decisões de Design e Programação
Esta função aceita como argumentos, um e apenas um argumento, sendo ele um nome literal de um ficheiro ou um padrão de pesquisa. Os resultados obtidos depois são dispostos numa tabela bem formatada, onde para além do nome do ficheiro, mostra o ID único, o tipo (diretoria ou não) o tamanho em MB ou KB e o nome do utilizador que criou o ficheiro.

- Explicação do algoritmo

A função search_recycle permite ao utilizador fazer a pesquisa por um ficheiro ou padrão dentro da recycle bin mostrando os dados de forma interativa.
Esta começa por verificar se o argumento passado está vazio ou não. Caso esteja, é dado um erro, dizendo o que o utilizador deve fazer
De seguida muda o diretório onde estamos a trabalhar para o pasta onde estão os ficheiros e são reunidos num vetor todos os ficheiro que correspondem ao padrão passado como argumento. 
Caso não haja qualquer ficheiro o programa retorna um erro dizendo que não foi encontrado qualquer ficheiro com os parametro da pesquisa
Caso contrário o programa vao iterar sobre o vetor do ficheiro que encontrou na pesquisa obtem o ID único, o tamanho, o tipo de ficheiro e o utilizador que o criou. 
Por fim cria uma tabela formatada, onde dispõe os ficheiros encontrado assim como os outros valores obtidos, regista a pesquisa no log e retorna sem erros

# Function - display_help()
[Ver Imagem](screenshots/DisplayHelpDiagram.png)
- Descrição da função 
A função display_help dispõe informações sobre o funcionamento da recycle bin. O objetivo desta função é auxiliar o utilizador caso não saiba algum comando, dispondo a informação de forma intuitiva

- Decisões de Design e Programação
Esta função não tem qualquer argumento, é apenas uma função auxiliar ao utilizador, sendo disposta a informação de forma intuitiva, isto é, com sintaxes, como inicializar, com exemplos e uma pequena descrição sobre cada comando

- Explicação do algoritmo
O algoritmos em si é muito básico. O que ele faz é simplesmente imprimir a informação sobre qual q sua sintaxe, uma descrição do que faz e exemplos. Recorre ao comando "echo" que consegue imprimir texto e à flag "-e" permite interpretar a mudança de linha. 
Abaixo encontra-se o output da função:
[ver output(parte 1)](screenshots/Display_help.png)
[ver output(parte 2)](screenshots/Display_help_2.png)
[ver output(parte 3)](screenshots/Display_help_3.png)

# Function - show_statistics
[Ver Imagem](screenshots/ShowStatisticDiagram.png)

- Descrição da Função
A função show_statistics mostra algumas informções acerca do estado da recycle bin. O objetivo desta função é fornecer informção suficiente ao utilizador de forma a decidir se deve ou não fazer uma otimização.

- Decisões de Design e Programação
Esta função não tem qualquer argumento e mostra informações como: O número de ficheiros na recycle, o total de espaço utilizado em percentagem, o ficheiro mais pesado, ficheiro mais recente e mais antigo e por fim, os resto dos ficheiros agrupados por diretórios e ficheiros normais.

- Explicação do algoritmo
O programa por chamar um ficheiro externo onde contém alguma variáveis globais, como a MAS_SIZE_MB, que diz o limite de tamanho total dos ficheiros deixados na recyle. Depois verifica se o diretório dos ficheiros está vazio, criando um array com todos os ficheiro que estão guardados dentro da diretoria e depois verificando o se o seu tamanho é igual a 0. Caso esteja diz apenas que está vazio retorna sem erros
De seguida vai buscar o número de ficheiro, que é o tamanho do array. 
Agora para achar o ficheiro mais pesado é feita uma iteração sobre todos os ficheiros onde é encontrado o ficheiro com maior tamanho recorrendo ao comando "stat -c%s <file>" para obter o tamanho(em bytes) do ficheiro. No fim é impresso o nome do ficheiro e o tamanho
De seguida passamos para a procura pelo ficheiro mais novo e mais velho, onde a lógica usada é similar à para achar o ficheiro mais pesado, a única é que temos de usar a data e o comando que é usado é "grep -m1 ",$(basename "$file")," "$METADATA_FILE" | awk -F',' '{print $4}'" que retira do metadata.bd o valor da data em que o ficheiro foi movido e depois convertida para segundos. No fim devolve os ficheiro encontrado(o mais novo e o mais velho respetivamente)
Por fim itera-se uma ultima vez pelo array dos ficheiro e divide-se em dois arrays de forma a poder agrupar os ficheiros por tipo( diretoria ou ficheiro normal), regista no log e retorna sem erros

# Function - auto_cleanup()
[Ver imagem](screenshots/AutoCleanupDiagram.png)
- Descrição da Função 
A função auto_cleanup permite ao utilizador fazer uma limpeza à recycle bin. Todos os arquivos que estão há muito tempo na recycle são eliminados permanentemente. O objetivo desta função é tornar a recycle bin mais leve de forma a ter uma melhor performance.

- Decisões de Design e Programação
Esta função tem apenas um argumento opcional "test" que ativa um modo teste de modo a facilitar a realização de testes no programa. Esta função também importa algumas variáveis como a RETENTION_DAYS que guarda o número de dias em que um ficheiro pode permanecer na recycle e a MAX_SIZE_MB  que guarda o limite de espaço que a recycle bin deve ter no total.

- Explicação do algoritmo
O programa começa por verificar se o ficheiro config, que contem as variáveis globais, e o ficheiro de metadata existem e caso não existam retorna um erro.
Verifica, de seguida, o primeiro argumento (caso tenha) se coincide com a palavra "test" o que ativa o modo teste definindo quer a variável RETENTION_DAYS quer a variável MAS_SIZE_MB  para 1(em dias e em MB respetivamente).
Depois verifica se as variáveis globais têm algum valor. Caso não tenham, retorna um erro.
Caso contrário é feito mais uma vez um array com todos os ficheiros movidos para a recycle e depois o programa itera sobre esse array. Ao iterar, verifica se cada valor do array é um ficheiro e, caso seja, obtem a data à qual foi movido para o recycle. De seguida verifica se a data está vazia e, caso não esteja, converte-a para dias, onde depois é comparada com a data e hora atual(em dias) e verifica se a sua diferença é maior que o número de dias no RETENTION_DAYS. Caso seja, o ficheiro é removido do diretório e o seu registo na metadata é eliminado.
Por fim, regista no log o que foi eliminado(caso tenha sido eliminado algum ficheiro), que já está otimizada e retorna sem erros.

# Function - check_quota()
[Ver imagem](screenshots/checkQuotaDiagram.png)
- Descrição da Função
A função check_quota verifica se o montante de ficheiros armazenados na recycle excede(ou não) o limite da recycle. O objetivo desta função é perceber o quão cheia está a recycle e caso seja possível limpar os ficheiros, otimizando a recycle bin.

- Decisões de Design e Programação
Esta função tem apenas um argumento opcional "test" que ativa um modo de teste igual ao anterior, facilitando assim a realização de testes. Esta função também para além de fazer a verificação, caso esteja cheia o programa pede uma resposta ao utilizador se pode ou não fazer uma limpeza, isto é, chamar a função auto_clean para limpar os ficheiro que estão há muito tempo na recycle. Isto permite uma flexibilização e uma automatização do processo de limpeza e de aumento de performance da recycle bin.

- Explicação do algoritmo
O programa começa por verificar se o ficheiro config, metadata e a diretoria dos ficheiro existem(Caso não existam, retorna um erro). De seguida, verifica se o primeiro argumento coincide com a palavra "test". Caso coincida, define MAX_SIZE_MB para 1(MB). Depois verifica se a variavel MAX_SIZE_MB está vazia(Retorna um erro caso esteja vazia). 
Após fazer as verificações, calcula o tamanho da diretoria dos ficheiro recorrendo ao comando "du -sm "$FILES_DIR" | cut -f1" e caso esse tamanho seja maior ou igual do que o valor de MAX_SIZE_MB o programa pede permissão ao utilizador para fazer uma limpeza, isto é chamar automaticamente a função auto_cleanup que verifica se há algum ficheiro há muito tempo na recycle. Caso contrário, o programa pula para o fim, registando no log e retorna sem erros.
Por fim verifica se conseguiu resolver o problema, fazendo um retorno de acordo, retorna sem erros caso tenha resolvido o problema e com erros caso contrário.