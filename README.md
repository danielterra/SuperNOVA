# SuperNOVA

Uma plataforma no-code sem dependências que roda localmente, permitindo armazenar informações e criar automações, incluindo integrações com serviços externos via webhooks e APIs.

## 🎯 Características

- **100% Local**: Executa completamente na sua máquina, sem necessidade de servidores externos
- **Zero Dependências**: Não requer infraestrutura adicional para funcionar
- **No-Code**: Interface intuitiva para criar automações sem programar
- **Armazenamento Flexível**: Suporta todo tipo de informação
- **Integrações Web**: Webhooks e chamadas de API para serviços externos
- **Logging Avançado**: Sistema completo de logs com níveis de severidade

## 🧩 Abstrações No-Code

A plataforma SuperNOVA é baseada em quatro abstrações fundamentais que permitem modelar qualquer tipo de dado e automação:

### 1. Classe

Define um tipo de objeto no sistema, similar a classes na programação orientada a objetos.

**Estrutura:**
- **Nome**: Identificador da classe (ex: "Pessoa", "Produto", "Tarefa")
- **Ícone**: Representação visual
- **Descrição**: Significado e propósito da classe
- **Propriedades**: Lista de atributos que objetos desta classe possuem

### 2. Propriedade

Atributos que definem as características de uma classe. Cada classe pode ter N propriedades.

**Tipos de Propriedade:**

*Tipos Simples:*
- **Texto**: Strings e texto livre
- **Número**: Valores numéricos inteiros ou decimais
- **Moeda**: Valores monetários
- **Data**: Apenas data (sem hora)
- **Data e hora**: Timestamp completo
- **Duração**: Intervalo de tempo

*Tipos Complexos:*
- **Localização**: Coordenadas geográficas (latitude/longitude)
- **Imagens**: Arquivos de imagem
- **Arquivos**: Documentos e arquivos em geral
- **Áudios**: Arquivos de áudio

*Tipos Relacionais:*
- **Referência**: Relacionamento com outros objetos (única ou múltipla)
  - Referência única: Aponta para um objeto
  - Referência múltipla: Aponta para vários objetos (array de IDs)

### 3. Estado

Define em qual situação ou condição um objeto se encontra.

**Características:**
- Cada classe define seus próprios estados possíveis
- Todo objeto **deve** estar em um estado a qualquer momento
- Exemplos comuns: ativo, inativo, rascunho, pendente, aprovado, concluído, cancelado

**Exemplo:**
Uma classe "Tarefa" pode ter os estados: `rascunho → em andamento → concluída → arquivada`

### 4. Ação

Executa transformações nos dados ou emite sinais para sistemas externos.

**Estrutura:**
- **Nome**: Identificador da ação (obrigatório)
- **Ícone**: Representação visual (opcional)
- **Descrição**: Explicação do que a ação faz (opcional)

**Características:**
- **Restrição por Estado**: Ações só podem ser executadas quando o objeto está em estados específicos
- **Efeitos**:
  - Transforma informações do objeto
  - Emite sinais para outros sistemas (webhooks, APIs)

**Tipos de Acionamento:**
- **Automático**: Executada automaticamente em resposta a mudanças de estado
- **Manual**: Iniciada explicitamente pelo usuário

**Exemplo:**
Uma classe "Pedido" pode ter a ação "Enviar Email de Confirmação" que só é permitida no estado "aprovado" e pode ser acionada automaticamente ao mudar para esse estado.

---

## 🏗️ Arquitetura Técnica

O projeto é construído em Swift/SwiftUI e consiste em:

### Componentes Principais

- **HTTPServer** (`HTTPServer.swift`): Servidor HTTP nativo que escuta na porta 8080
- **LogManager** (`LogManager.swift`): Sistema centralizado de gerenciamento de logs
- **ContentView** (`ContentView.swift`): Interface gráfica para visualização em tempo real dos logs do servidor
- **SwiftData**: Persistência de logs e dados

### Estrutura de Logs

O sistema de logging possui três níveis de severidade:
- `info`: Informações gerais
- `warning`: Avisos
- `error`: Erros com detalhes do código de erro do sistema

## 🚀 Como Usar

1. Abra o projeto no Xcode
2. Execute a aplicação
3. O servidor iniciará automaticamente na porta **8080**
4. Acesse `http://localhost:8080` para interagir com o servidor
5. Monitore todas as requisições e eventos em tempo real na interface

## 📝 Funcionalidades Implementadas

- ✅ Servidor HTTP básico rodando na porta 8080
- ✅ Sistema de logging persistente com SwiftData
- ✅ Interface de visualização de logs em tempo real
- ✅ Registro detalhado de requisições HTTP (método, path, headers, versão HTTP)
- ✅ Scroll automático para logs mais recentes
- ✅ Indicadores visuais para diferentes níveis de severidade

## 🛠️ Tecnologias

- Swift
- SwiftUI
- SwiftData
- BSD Sockets (servidor HTTP nativo)

## 📦 Requisitos

- macOS com Xcode instalado
- Swift 5.9+

## 🔮 Roadmap

- [ ] Sistema de armazenamento de dados flexível
- [ ] Editor visual de automações no-code
- [ ] Suporte a webhooks (entrada e saída)
- [ ] Cliente HTTP para chamadas de API externas
- [ ] Sistema de regras e triggers
- [ ] Templates de integrações comuns

---

Desenvolvido com Swift/SwiftUI
