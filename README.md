# 沈黙の翼 - As Asas do Silêncio

> NFT do Livro "As Asas do Silêncio" - Uma fábula samurai por Bruno Kaze

[![Solidity](https://img.shields.io/badge/Solidity-0.8.24-363636?logo=solidity)](https://soliditylang.org/)
[![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-v5.4.0-4E5EE4?logo=openzeppelin)](https://openzeppelin.com/contracts/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C?logo=foundry)](https://getfoundry.sh/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 📖 Sobre o Projeto

**As Asas do Silêncio** é o primeiro volume de uma trilogia escrita e ilustrada por **Bruno Kaze**, que une aventura épica, espiritualidade oriental e uma estética poética singular.

> *Em um mundo onde o silêncio corta mais fundo que a lâmina, a honra é posta à prova. Após a morte de seu mestre, uma libélula samurai é traída por aqueles em quem confiava e lançada ao exílio. Ferido, mas não vencido, Takeshi parte em uma jornada por terras esquecidas...*

Este repositório contém o **token ERC-1155** que representa a propriedade digital única (NFT) da primeira edição impressa do livro.

---

## 🏗️ Estrutura do Projeto

```
asasdosilencio/
├── docs/                      # Frontend (GitHub Pages)
│   ├── index.html            # Landing page com tema samurai japonês
│   ├── 404.html              # Página de erro com estética Zen
│   ├── favicon.ico           # Ícone do Takeshi
│   ├── capalivro.png         # Capa do livro
│   ├── metadata/             # Metadados JSON do ERC-1155
│   └── CNAME                 # Domínio customizado
│
└── smartcontracts/           # Contratos Solidity
    ├── src/
    │   └── book.sol          # Contrato ERC-1155 Book
    ├── test/
    │   └── Book.t.sol        # Suite de testes (42 testes)
    ├── lib/
    │   └── openzeppelin-contracts/  # OpenZeppelin v5.4.0
    ├── foundry.toml          # Configuração Foundry
    └── remappings.txt        # Mapeamento de imports
```

---

## 📜 Smart Contract

### Token ID Encoding

Cada livro é único e identificado por um `tokenId` que codifica:
- **Edition** (edição): número da edição
- **Item**: número do item dentro da edição

```
tokenId = edition × 1,000,000 + item
```

Exemplo: Edição 1, Item 42 → `tokenId = 1000042`

### Principais Funções

| Função | Descrição |
|--------|-----------|
| `mint(to, edition, item)` | Cunha um token único para o destinatário |
| `mintBatch(to, editions[], items[])` | Cunha múltiplos tokens em lote |
| `encodeTokenId(edition, item)` | Codifica edição/item em tokenId |
| `decodeTokenId(tokenId)` | Decodifica tokenId em edição/item |
| `uri(tokenId)` | Retorna URI dos metadados |
| `setBaseURI(newBaseURI)` | Atualiza URI base (apenas owner) |

---

## 🛠️ Desenvolvimento

### Pré-requisitos

- [Foundry](https://getfoundry.sh/) instalado
- Git

### Instalação

```bash
# Clone o repositório
git clone https://github.com/novatrixtech/asasdosilencio.git
cd asasdosilencio/smartcontracts

# Instale dependências (já incluídas como submodules)
forge install

# Compile
forge build

# Execute testes
forge test -vv
```

### Testes

O projeto inclui **42 testes** cobrindo:

- ✅ Constructor e inicialização
- ✅ Codificação/decodificação de Token ID
- ✅ Funções de URI
- ✅ Mint individual e em lote
- ✅ Transferências ERC-1155
- ✅ Aprovações e operadores
- ✅ Controle de acesso (Ownable)
- ✅ Casos de borda

```bash
forge test -vv
# Ran 42 tests: 42 passed, 0 failed
```

---

## 🎨 Frontend

O frontend está hospedado no GitHub Pages com tema visual inspirado em:
- 🏯 Estética samurai japonesa antiga
- 📜 Papel washi e tinta sumi
- ⛩️ Tipografia com fontes Noto Serif JP e Cinzel
- 🔴 Paleta: ink black, vermillion, gold accent

### Visualizar Localmente

```bash
cd docs
python -m http.server 8000
# Acesse http://localhost:8000
```

---

## 📋 Metadados ERC-1155

Os metadados seguem o padrão ERC-1155 e ficam em `docs/metadata/`:

```json
{
  "name": "As Asas do Silêncio - Edição 1 #42",
  "description": "Token único da primeira edição impressa",
  "image": "https://novatrixtech.github.io/asasdosilencio/capalivro.png",
  "attributes": [
    { "trait_type": "Edition", "value": 1 },
    { "trait_type": "Item", "value": 42 },
    { "trait_type": "Author", "value": "Bruno Kaze" }
  ]
}
```

---

## 🔗 Links

- **Frontend**: [novatrixtech.github.io/asasdosilencio](https://novatrixtech.github.io/asasdosilencio/)
- **Autor**: Bruno Kaze

---

## 📄 Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

---

<p align="center">
  <strong>沈黙の翼</strong><br/>
  <em>"Mais do que uma fábula, é um chamado à verdade e ao voo interior de quem ousa escutar o silêncio."</em>
</p>
