# MemorizeCard API - Documentação

## 📋 Índice
- [Visão Geral](#visão-geral)
- [Autenticação](#autenticação)
- [Endpoints](#endpoints)
  - [Configuração](#configuração)
  - [Autenticação e Usuários](#autenticação-e-usuários)
  - [Decks](#decks)
  - [Cards](#cards)
  - [Geração de Cards com IA](#geração-de-cards-com-ia)
  - [Recuperação de Senha](#recuperação-de-senha)
- [Modelos de Dados](#modelos-de-dados)
- [Códigos de Status](#códigos-de-status)

---

## Visão Geral

**Base URL:** `http://localhost:3000/api`

**Formato de Resposta:** JSON

**Autenticação:** JWT (JSON Web Token) via header `Authorization: Bearer <token>`

---

## Autenticação

A maioria dos endpoints requer autenticação JWT. Após fazer login ou criar uma conta, você receberá um token JWT que deve ser incluído no header de todas as requisições autenticadas:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

### Endpoints Públicos (não requerem autenticação):
- `GET /api/config`
- `POST /api/users` (criar conta)
- `POST /api/login`
- `POST /api/auth/google_oauth2/callback`
- `POST /api/password/forgot`
- `POST /api/password/validate-token`
- `POST /api/password/reset`
- `GET /up` (health check)

---

## Endpoints

### Configuração

#### `GET /api/config`
Retorna configurações públicas da aplicação (ex: Google Client ID).

**Autenticação:** Não requerida

**Resposta de Sucesso (200):**
```json
{
  "google_client_id": "123456789-abc.apps.googleusercontent.com"
}
```

---

### Autenticação e Usuários

#### `POST /api/users`
Cria uma nova conta de usuário.

**Autenticação:** Não requerida

**Corpo da Requisição:**
```json
{
  "user": {
    "full_name": "João Silva",
    "email": "joao@example.com",
    "password": "senha123",
    "password_confirmation": "senha123"
  }
}
```

**Resposta de Sucesso (201):**
```json
{
  "user": {
    "id": 1,
    "email": "joao@example.com",
    "full_name": "João Silva"
  },
  "jwt": "eyJhbGciOiJIUzI1NiJ9..."
}
```

**Resposta de Erro (422):**
```json
{
  "errors": [
    "Email já está em uso",
    "Senha é muito curta"
  ]
}
```

---

#### `POST /api/login`
Faz login com email e senha.

**Autenticação:** Não requerida

**Corpo da Requisição:**
```json
{
  "email": "joao@example.com",
  "password": "senha123"
}
```

**Resposta de Sucesso (200):**
```json
{
  "user": {
    "id": 1,
    "email": "joao@example.com",
    "full_name": "João Silva"
  },
  "jwt": "eyJhbGciOiJIUzI1NiJ9..."
}
```

**Resposta de Erro (401):**
```json
{
  "error": "Email ou senha inválidos"
}
```

---

#### `POST /api/auth/google_oauth2/callback`
Autentica via Google OAuth2.

**Autenticação:** Não requerida

**Corpo da Requisição:**
```json
{
  "token": "eyJhbGciOiJSUzI1NiIsImtpZCI6..."
}
```

**Resposta de Sucesso (200):**
```json
{
  "user": {
    "id": 1,
    "email": "joao@example.com",
    "full_name": "João Silva"
  },
  "jwt": "eyJhbGciOiJIUzI1NiJ9..."
}
```

**Resposta de Erro (401):**
```json
{
  "error": "Invalid Google ID Token: <mensagem>"
}
```

---

### Decks

#### `GET /api/decks`
Lista todos os decks do usuário autenticado.

**Autenticação:** Requerida

**Resposta de Sucesso (200):**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Inglês - Básico",
      "user_id": 1,
      "created_at": "2025-11-03T10:00:00.000Z",
      "updated_at": "2025-11-03T10:00:00.000Z",
      "cards": [
        {
          "id": 1,
          "term": "Hello",
          "definition": "Olá",
          "deck_id": 1,
          "last_difficulty": null,
          "last_view": null
        }
      ]
    }
  ]
}
```

---

#### `GET /api/decks/:id`
Retorna detalhes de um deck específico com seus cards.

**Autenticação:** Requerida

**Parâmetros de URL:**
- `id` (integer) - ID do deck

**Resposta de Sucesso (200):**
```json
{
  "data": {
    "id": 1,
    "name": "Inglês - Básico",
    "user_id": 1,
    "created_at": "2025-11-03T10:00:00.000Z",
    "updated_at": "2025-11-03T10:00:00.000Z",
    "cards": [
      {
        "id": 1,
        "term": "Hello",
        "definition": "Olá",
        "deck_id": 1
      }
    ]
  }
}
```

---

#### `POST /api/decks`
Cria um novo deck.

**Autenticação:** Requerida

**Corpo da Requisição:**
```json
{
  "deck": {
    "name": "Matemática - Geometria"
  }
}
```

**Resposta de Sucesso (201):**
```json
{
  "data": {
    "id": 2,
    "name": "Matemática - Geometria",
    "user_id": 1,
    "created_at": "2025-11-03T10:00:00.000Z",
    "updated_at": "2025-11-03T10:00:00.000Z"
  }
}
```

**Resposta de Erro (422):**
```json
{
  "errors": ["Name não pode ficar em branco"]
}
```

---

#### `PATCH /api/decks/:id`
Atualiza um deck existente.

**Autenticação:** Requerida

**Parâmetros de URL:**
- `id` (integer) - ID do deck

**Corpo da Requisição:**
```json
{
  "deck": {
    "name": "Inglês - Intermediário"
  }
}
```

**Resposta de Sucesso (200):**
```
(Sem corpo - apenas status 200)
```

---

#### `DELETE /api/decks/:id`
Remove um deck e todos seus cards.

**Autenticação:** Requerida

**Parâmetros de URL:**
- `id` (integer) - ID do deck

**Resposta de Sucesso (204):**
```
(Sem corpo - status 204 No Content)
```

---

#### `GET /api/decks/:id/export`
Exporta um deck do usuário autenticado em JSON compartilhável.

**Autenticação:** Requerida

**Parâmetros de URL:**
- `id` (integer) - ID do deck

**Resposta de Sucesso (200):**
```json
{
  "data": {
    "format": "memourize.deck",
    "version": 1,
    "deck": {
      "name": "Inglês - Básico",
      "cards": [
        {
          "term": "Hello",
          "definition": "Olá",
          "alternative_definitions": [
            {
              "content": "Cumprimento usado ao encontrar alguém.",
              "position": 1
            }
          ]
        }
      ]
    }
  }
}
```

---

#### `POST /api/decks/import`
Importa um deck a partir do JSON compartilhável exportado por outro usuário.

Use como corpo da requisição o conteúdo interno de `data` retornado pelo export.

**Autenticação:** Requerida

**Corpo da Requisição:**
```json
{
  "format": "memourize.deck",
  "version": 1,
  "deck": {
    "name": "Inglês - Básico",
    "cards": [
      {
        "term": "Hello",
        "definition": "Olá",
        "alternative_definitions": [
          {
            "content": "Cumprimento usado ao encontrar alguém.",
            "position": 1
          }
        ]
      }
    ]
  }
}
```

**Resposta de Sucesso (201):**
```json
{
  "data": {
    "id": 3,
    "name": "Inglês - Básico",
    "user_id": 2,
    "created_at": "2025-11-03T10:00:00.000Z",
    "updated_at": "2025-11-03T10:00:00.000Z",
    "cards": [
      {
        "id": 5,
        "term": "Hello",
        "definition": "Olá",
        "deck_id": 3,
        "last_difficulty": null,
        "last_view": null,
        "created_at": "2025-11-03T10:00:00.000Z",
        "updated_at": "2025-11-03T10:00:00.000Z"
      }
    ]
  }
}
```

**Resposta de Erro (422):**
```json
{
  "errors": ["Card 1 deve ter term e definition"]
}
```

---

### Cards

#### `GET /api/decks/:deck_id/cards`
Lista todos os cards de um deck.

**Autenticação:** Requerida

**Parâmetros de URL:**
- `deck_id` (integer) - ID do deck

**Resposta de Sucesso (200):**
```json
{
  "data": [
    {
      "id": 1,
      "term": "Hello",
      "definition": "Olá",
      "deck_id": 1,
      "last_difficulty": "easy",
      "last_view": "2025-11-03",
      "created_at": "2025-11-03T10:00:00.000Z",
      "updated_at": "2025-11-03T10:00:00.000Z"
    }
  ]
}
```

---

#### `POST /api/decks/:deck_id/cards`
Cria um novo card em um deck.

**Autenticação:** Requerida

**Parâmetros de URL:**
- `deck_id` (integer) - ID do deck

**Corpo da Requisição:**
```json
{
  "card": {
    "term": "Goodbye",
    "definition": "Tchau"
  }
}
```

**Resposta de Sucesso (201):**
```json
{
  "data": {
    "id": 2,
    "term": "Goodbye",
    "definition": "Tchau",
    "deck_id": 1,
    "last_difficulty": null,
    "last_view": null,
    "created_at": "2025-11-03T10:00:00.000Z",
    "updated_at": "2025-11-03T10:00:00.000Z"
  }
}
```

**Resposta de Erro (422):**
```json
{
  "errors": ["Term não pode ficar em branco"]
}
```

---

#### `PATCH /api/cards/:id`
Atualiza um card existente.

**Autenticação:** Requerida

**Parâmetros de URL:**
- `id` (integer) - ID do card

**Corpo da Requisição:**
```json
{
  "card": {
    "term": "Hi",
    "definition": "Oi"
  }
}
```

**Resposta de Sucesso (200):**
```json
{
  "data": {
    "id": 1,
    "term": "Hi",
    "definition": "Oi",
    "deck_id": 1,
    "last_difficulty": null,
    "last_view": null
  }
}
```

---

#### `DELETE /api/cards/:id`
Remove um card.

**Autenticação:** Requerida

**Parâmetros de URL:**
- `id` (integer) - ID do card

**Resposta de Sucesso (204):**
```
(Sem corpo - status 204 No Content)
```

---

#### `POST /api/cards/:id/done`
Marca um card como estudado/revisado.

**Autenticação:** Requerida

**Parâmetros de URL:**
- `id` (integer) - ID do card

**Corpo da Requisição:**
```json
{
  "difficulty": "easy"
}
```

**Valores aceitos para `difficulty`:**
- `"easy"` - Fácil
- `"medium"` - Médio
- `"hard"` - Difícil

**Resposta de Sucesso (200):**
```
(Sem corpo - apenas status 200)
```

**Resposta de Erro (422):**
```json
{
  "errors": ["Erro ao atualizar card"]
}
```

---

### Geração de Cards com IA

#### `POST /api/generate_cards_ia`
Gera cards automaticamente a partir de um arquivo (PDF ou imagem) usando IA.

**Autenticação:** Requerida

**Tipo de Requisição:** `multipart/form-data`

**Parâmetros:**
- `file` (file, obrigatório) - Arquivo PDF ou imagem (PNG, JPG)
- `deck_name` (string, opcional) - Nome do deck a ser criado

**Exemplo (usando FormData):**
```javascript
const formData = new FormData();
formData.append('file', fileInput.files[0]);
formData.append('deck_name', 'História - Segunda Guerra');

fetch('http://localhost:3000/api/generate_cards_ia', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`
  },
  body: formData
});
```

**Resposta de Sucesso (201):**
```json
{
  "deck": {
    "id": 3,
    "name": "História - Segunda Guerra",
    "user_id": 1
  },
  "cards": [
    {
      "id": 5,
      "term": "Quando começou a Segunda Guerra?",
      "definition": "1939",
      "deck_id": 3
    },
    {
      "id": 6,
      "term": "Quando terminou a Segunda Guerra?",
      "definition": "1945",
      "deck_id": 3
    }
  ]
}
```

**Resposta de Erro (400):**
```json
{
  "error": "Arquivo não enviado"
}
```

**Resposta de Erro (422):**
```json
{
  "error": "Resposta inválida da IA"
}
```

---

### Recuperação de Senha

#### `POST /api/password/forgot`
Solicita recuperação de senha (envia código por email).

**Autenticação:** Não requerida

**Corpo da Requisição:**
```json
{
  "email": "joao@example.com"
}
```

**Resposta de Sucesso (200):**
```
(Sem corpo - sempre retorna 200 por segurança)
```

**Observação:** Por questões de segurança, sempre retorna 200 mesmo se o email não existir.

---

#### `POST /api/password/validate-token`
Valida o código de recuperação recebido por email.

**Autenticação:** Não requerida

**Corpo da Requisição:**
```json
{
  "email": "joao@example.com",
  "code": "1234"
}
```

**Resposta de Sucesso (200):**
```
(Sem corpo - apenas status 200)
```

**Resposta de Erro (400):**
```json
{
  "message": "invalid token"
}
```

---

#### `POST /api/password/reset`
Redefine a senha usando o código validado.

**Autenticação:** Não requerida

**Corpo da Requisição:**
```json
{
  "email": "joao@example.com",
  "code": "1234",
  "password": "novaSenha123"
}
```

**Resposta de Sucesso (200):**
```
(Sem corpo - apenas status 200)
```

**Resposta de Erro (400):**
```json
{
  "message": "invalid token"
}
```

---

## Modelos de Dados

### User
```json
{
  "id": 1,
  "email": "joao@example.com",
  "full_name": "João Silva",
  "created_at": "2025-11-03T10:00:00.000Z",
  "updated_at": "2025-11-03T10:00:00.000Z"
}
```

### Deck
```json
{
  "id": 1,
  "name": "Inglês - Básico",
  "user_id": 1,
  "created_at": "2025-11-03T10:00:00.000Z",
  "updated_at": "2025-11-03T10:00:00.000Z"
}
```

### Card
```json
{
  "id": 1,
  "term": "Hello",
  "definition": "Olá",
  "deck_id": 1,
  "last_difficulty": "easy",
  "last_view": "2025-11-03",
  "created_at": "2025-11-03T10:00:00.000Z",
  "updated_at": "2025-11-03T10:00:00.000Z"
}
```

---

## Códigos de Status

| Código | Significado |
|--------|-------------|
| 200 | OK - Requisição bem-sucedida |
| 201 | Created - Recurso criado com sucesso |
| 204 | No Content - Sucesso sem corpo de resposta |
| 400 | Bad Request - Requisição inválida |
| 401 | Unauthorized - Não autenticado ou token inválido |
| 404 | Not Found - Recurso não encontrado |
| 422 | Unprocessable Entity - Erros de validação |
| 500 | Internal Server Error - Erro interno do servidor |

---

## Exemplos de Uso

### Exemplo Completo: Criar Conta e Deck

```javascript
// 1. Criar conta
const signupResponse = await fetch('http://localhost:3000/api/users', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    user: {
      full_name: 'João Silva',
      email: 'joao@example.com',
      password: 'senha123',
      password_confirmation: 'senha123'
    }
  })
});
const { jwt } = await signupResponse.json();

// 2. Criar um deck
const deckResponse = await fetch('http://localhost:3000/api/decks', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${jwt}`
  },
  body: JSON.stringify({
    deck: { name: 'Inglês - Básico' }
  })
});
const { data: deck } = await deckResponse.json();

// 3. Adicionar card ao deck
const cardResponse = await fetch(`http://localhost:3000/api/decks/${deck.id}/cards`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${jwt}`
  },
  body: JSON.stringify({
    card: {
      term: 'Hello',
      definition: 'Olá'
    }
  })
});
```

---

## Health Check

#### `GET /up`
Verifica se a aplicação está rodando.

**Autenticação:** Não requerida

**Resposta de Sucesso (200):**
```
OK
```

---

## Variáveis de Ambiente

Certifique-se de configurar as seguintes variáveis no arquivo `.env`:

```bash
# Google OAuth
GOOGLE_CLIENT_ID=seu_client_id.apps.googleusercontent.com

# Gemini AI (para geração de cards)
GEMINI_API_KEY=sua_api_key_do_gemini

# JWT (opcional, Rails usa secret_key_base por padrão)
JWT_SECRET_KEY=sua_chave_secreta
```

---

## Contato e Suporte

Para mais informações, consulte o repositório:
- **GitHub:** https://github.com/ProjetoAplicWeb/MemorizeCard-api

---

**Última atualização:** Novembro 2025
