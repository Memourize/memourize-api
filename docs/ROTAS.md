# MemorizeCard API - Rotas Rápidas

## 🔓 Rotas Públicas (sem autenticação)

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/up` | Health check |
| GET | `/api/config` | Configurações públicas (Google Client ID) |
| POST | `/api/users` | Criar conta |
| POST | `/api/login` | Login com email/senha |
| POST | `/api/auth/google_oauth2/callback` | Login com Google |
| POST | `/api/password/forgot` | Solicitar recuperação de senha |
| POST | `/api/password/validate-token` | Validar código de recuperação |
| POST | `/api/password/reset` | Redefinir senha |

---

## 🔒 Rotas Protegidas (requerem JWT)

### Decks
| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/api/decks` | Listar todos os decks do usuário |
| GET | `/api/decks/:id` | Detalhes de um deck específico |
| POST | `/api/decks` | Criar novo deck |
| PATCH | `/api/decks/:id` | Atualizar deck |
| DELETE | `/api/decks/:id` | Deletar deck |
| GET | `/api/decks/:id/export` | Exportar deck como JSON compartilhável |
| POST | `/api/decks/import` | Importar deck a partir de JSON compartilhável |

### Cards
| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/api/decks/:deck_id/cards` | Listar cards de um deck |
| POST | `/api/decks/:deck_id/cards` | Criar card em um deck |
| PATCH | `/api/cards/:id` | Atualizar card |
| DELETE | `/api/cards/:id` | Deletar card |
| POST | `/api/cards/:id/done` | Marcar card como estudado |

### IA (Gemini)
| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/api/generate_cards_ia` | Gerar cards a partir de arquivo (PDF/imagem) |

---

## 📝 Formatos de Requisição Rápidos

### Criar Conta
```json
POST /api/users
{
  "user": {
    "full_name": "Nome Completo",
    "email": "email@example.com",
    "password": "senha123",
    "password_confirmation": "senha123"
  }
}
```

### Login
```json
POST /api/login
{
  "email": "email@example.com",
  "password": "senha123"
}
```

### Criar Deck
```json
POST /api/decks
Headers: { "Authorization": "Bearer <token>" }
{
  "deck": {
    "name": "Nome do Deck"
  }
}
```

### Criar Card
```json
POST /api/decks/:deck_id/cards
Headers: { "Authorization": "Bearer <token>" }
{
  "card": {
    "term": "Termo/Pergunta",
    "definition": "Definição/Resposta"
  }
}
```

### Marcar Card como Estudado
```json
POST /api/cards/:id/done
Headers: { "Authorization": "Bearer <token>" }
{
  "difficulty": "easy"  // ou "medium", "hard"
}
```

### Gerar Cards com IA
```javascript
POST /api/generate_cards_ia
Headers: { "Authorization": "Bearer <token>" }
Content-Type: multipart/form-data

FormData:
- file: <arquivo PDF ou imagem>
- deck_name: "Nome do Deck" (opcional)
```

---

## 🔑 Autenticação

Após login ou criação de conta, inclua o JWT no header:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

---

## 📊 Códigos de Status Comuns

- `200` - OK
- `201` - Criado
- `204` - Sem conteúdo (sucesso)
- `400` - Requisição inválida
- `401` - Não autorizado
- `404` - Não encontrado
- `422` - Erro de validação
- `500` - Erro interno

---

## 🚀 Exemplo de Fluxo Completo

```bash
# 1. Criar conta
POST /api/users → recebe JWT

# 2. Criar deck
POST /api/decks (com JWT) → recebe deck.id

# 3. Criar cards
POST /api/decks/{deck.id}/cards (com JWT)

# 4. Listar decks e cards
GET /api/decks (com JWT)

# 5. Estudar cards
POST /api/cards/{card.id}/done (com JWT)
```

---

Para documentação completa, consulte [API.md](./API.md)
