if [[ "$(uname -m)" == arm64 ]]
then
    export PATH="/opt/homebrew/bin:$PATH"
fi

if command -v swiftlint >/dev/null 2>&1
then
    swiftlint --config ../Application/swiftlint.yml
else
    echo "Swiftlint não encontrado no sistema. Fazendo o download da versao mais recente ..."
    brew install swiftlint
    echo "Swiftlint instalado com sucesso. Prepara a Aspirina."
    swiftlint
fi
