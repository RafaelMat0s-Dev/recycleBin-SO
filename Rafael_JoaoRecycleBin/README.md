
# Linux Recycle Bin System
## Author
[Rafael da Costa Matos]
[124685]
[João Miguel Padrão Neves]
## Description

[Este Projeto tem o objetivo de replicar o a pasta do lixo (ou recycle_bin) implementando todas as funcionalidades básicas que compoẽm este pedaço de software]
## Installation

1º- Dar Clone ao Repositório do Github -> git clone https://github.com/RafaelMat0s-Dev/recycleBin-SO.git
2º- Começar a Utilizar os Comandos de acordo com a documentação

## Usage

Dentro da pasta Rafael_JoaoRecycleBin executar os comandos
    ./recycle_bin.sh [commandName] [Argumentos] -> para executar os comandos pela linha de comando
    ./recycle_bin_gui.sh -> para executar a interface de comandos
    ./test_suite.sh ou ./test_suite.sh --detailed --> para testar a interface de testes automatizados
## Features
- initialize_recyclebin()
- delete_file()
- list_recycled()
- restore_file()
- search_recycled()
- empty_recyclebin()
- display_help()

Optional Features
- preview_file()

## Configuration
O ficheiro de configuração é criado na pasta base da reciclagem quando o comando ./recycle_bin.sh é executado

## Examples
[Detailed usage examples with screenshots]
## Known Issues
[Any limitations or bugs]
## References
https://www.w3schools.com/bash/bash_rm.php
https://stackoverflow.com/questions/185451/quick-and-dirty-way-to-ensure-only-one-instance-of-a-shell-script-is-running-at
https://github.com/tonymorello/trash
https://askubuntu.com/questions/213533/command-to-move-a-file-to-trash-via-terminal
https://www.freecodecamp.org/news/linux-chmod-chown-change-file-permissions/
https://opensource.com/article/18/7/how-check-free-disk-space-linux

