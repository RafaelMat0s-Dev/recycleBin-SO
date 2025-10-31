
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
O ficheiro de configuração permite ajustar parâmetros sem alterar o código, e o log (recyclebin.log) assegura que sempre que se pretende fazer o debu de todas as ações pode-se consultar esse ficheiro para ver o que aconteceu
O script evita sobreescrever dados existentes, validando o ambiente e todos os ficheiros antes de os criar. Assim, garante-se que a inicialização é sempre previsível, segura e sem perdas de dados.

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
Formatação clara e legível com tabela resumida ou detalhada, incluindo conversão de tamanho para formato humano (numfmt).
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