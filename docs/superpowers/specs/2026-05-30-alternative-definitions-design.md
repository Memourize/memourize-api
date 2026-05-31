# Definições alternativas em cards gerados por IA — Design

**Data:** 2026-05-30
**Status:** Aprovado para planejamento

## Objetivo

Ao gerar um deck por IA, além da definição principal de cada card, gerar
algumas definições **alternativas** para o mesmo termo. Essas alternativas
ficam **ocultas** da listagem normal do deck e aparecem **apenas na revisão**,
de forma rotativa — a cada vez que o estudante revisa o card, ele vê outra
forma de explicar o mesmo conceito (outra perspectiva/resposta), sem aumentar
a quantidade de cards.

## Decisões

| Tema | Decisão |
|---|---|
| Armazenamento | Tabela nova de alternativas associada ao card. **Não** cria decks extras. |
| Visibilidade | Alternativas nunca aparecem nas listagens de gerenciamento do deck. |
| Na revisão | **Um** card por revisão; a definição mostrada é a "vista da vez" (rotativa). |
| Rotação | Ponteiro (`definition_cursor`) salvo no próprio card. |
| Geração | **Uma única chamada** à IA; cada item traz `definition` + `alternatives`. |
| Quantidade | Configurável; default **2** alternativas por card (fallback do modelo gratuito). |
| Escopo | Só fluxo de IA agora; modelo de dados genérico para suportar cards manuais no futuro. |
| Contrato | Na revisão, a definição da vez **substitui** o campo `definition` (front não muda). |
| Avanço do ponteiro | Ao marcar como estudado (`POST /api/cards/:id/done`). |

## Modelo de dados

### Nova tabela `card_alternative_definitions`

Tabela genérica (serve para qualquer card, não só os de IA).

- `card_id` — FK para `cards`, `null: false`, indexada.
- `content` — `string`/`text`, `null: false`. A definição alternativa.
- `position` — `integer`, `null: false`. Ordem estável: 1, 2, 3, …
- `created_at` / `updated_at`.

A definição **original** do card (`cards.definition`) **não** é duplicada nesta
tabela. Ela é a "vista 0".

### Nova coluna `cards.definition_cursor`

- `integer`, `null: false`, `default: 0`.
- `0` → mostra `cards.definition` (original).
- `k` (1..N) → mostra a alternativa cujo `position == k`.

### Relações

```ruby
class Card < ApplicationRecord
  has_many :alternative_definitions,
           class_name: "CardAlternativeDefinition",
           dependent: :destroy
end

class CardAlternativeDefinition < ApplicationRecord
  belongs_to :card
  validates :content, presence: true
  validates :position, presence: true
end
```

### Total de "vistas" por card

`1 (original) + número de alternativas`. Com o default de 2 alternativas, são
**3 vistas**. O número é configurável e tolerante: um card pode ter menos
alternativas (ou nenhuma) sem quebrar nada.

## Geração por IA

Tudo dentro de `GenerateCardsService` (`app/services/generate_cards_service.rb`).

### Constante

```ruby
ALTERNATIVES_PER_CARD = 2 # ajustável; conservador para o modelo gratuito
```

### Prompt

Ajustar `prompt_base` para pedir, em cada item, um campo `alternatives` com
`ALTERNATIVES_PER_CARD` definições alternativas. As alternativas devem explicar
o **mesmo conceito** com palavras/abordagem diferentes (outra perspectiva), não
conceitos novos. Formato esperado:

```json
[
  {
    "term": "termo 1",
    "definition": "definição principal",
    "alternatives": ["outra forma de explicar", "mais uma visão"]
  }
]
```

Subir `max_tokens` de 2048 para ~4096 para acomodar o conteúdo extra.

### Criação dos cards (`create_cards`)

Para cada item retornado:

1. Cria o `Card` com `term` + `definition` (como hoje).
2. Se `item["alternatives"]` for um array, cria um
   `CardAlternativeDefinition` por entrada **não-vazia**, com `position`
   sequencial (1, 2, …), via `card.alternative_definitions`.

### Tolerância a falhas (best-effort)

O contrato crítico continua sendo apenas `term` + `definition`. As alternativas
são um bônus e **nunca** podem quebrar a geração:

- `alternatives` ausente / `null` / não-array / vazio → card criado normalmente,
  sem alternativas, sem erro.
- entradas vazias ou em branco dentro do array são ignoradas.
- se a IA retornar menos alternativas que o pedido, salva-se o que vier.

Quando o card não tem alternativas, todo o sistema se comporta exatamente como
hoje.

## Revisão, rotação e ocultação

### Ocultação (não aparece na lista de cards)

As alternativas vivem apenas em `card_alternative_definitions` e **nunca** entram
no `as_json` padrão do card. Permanecem inalterados, sem vazar alternativas:

- `GET /api/decks/:deck_id/cards` (`cards#index`)
- `GET /api/decks` (`decks#index`)
- `GET /api/decks/:id` **sem** `ready_to_review` (`decks#show`)

Em qualquer visão de gerenciamento do deck, o card mostra só a `definition`
original.

### Rotação (apenas na revisão)

Ponto de exibição: `GET /api/decks/:id?ready_to_review=true` (`decks#show`).
Nessa resposta, cada card é serializado substituindo o campo `definition` pela
**vista da vez**, escolhida pelo `definition_cursor`:

- `definition_cursor == 0` → `definition` original.
- `definition_cursor == k` (1..N) → `content` da alternativa com `position == k`.
- cursor apontando para posição inexistente → cai na original (wrap seguro),
  nunca quebra.

O `term` é o mesmo; só o verso muda. O front continua lendo `term` +
`definition`, sem alteração.

Implementação: `decks#show` hoje faz `@deck.as_json.merge(cards: @cards)` com
`@cards` sendo uma relação. Para substituir a `definition`, mapear os cards para
um hash com a definição resolvida (helper no `Card`), ou introduzir um
`CardSerializer` enxuto. Mudança pequena e localizada nesse controller.

### Avanço do ponteiro (ao concluir o estudo)

Em `POST /api/cards/:id/done` (`cards#done`), além de registrar o `CardReview`
e atualizar `last_difficulty` / `last_view` como hoje, o `definition_cursor`
avança circulando:

```
próximo = (cursor_atual + 1) % (1 + número_de_alternativas_do_card)
```

Exemplo com 2 alternativas (3 vistas): `0 → 1 → 2 → 0 → …`.
Card sem alternativas: `(0 + 1) % 1 = 0` → fica sempre na original
(comportamento idêntico ao atual).

O avanço entra na **transação já existente** do `done`, junto da criação do
`CardReview`.

## Testes (Minitest + fixtures, `bin/rails test`)

### Modelos

- `CardAlternativeDefinition`: pertence a card; valida presença de `content` e
  `position`.
- `Card`:
  - `dependent: :destroy` — apagar card apaga suas alternativas.
  - helper que resolve a definição da vista atual a partir do
    `definition_cursor`, com wrap seguro.
  - helper que avança o cursor (circular).

### Serviço (`GenerateCardsService`)

- cria alternativas a partir do campo `alternatives` da IA;
- tolerância: `alternatives` ausente/`null`/não-array/vazio → card sem
  alternativas, sem erro;
- entradas vazias no array são ignoradas;
- usar o mesmo mecanismo de mock de IA já presente nos testes (sem rede real).

### Controllers

- `cards#done`: avança o cursor e circula corretamente; card sem alternativas
  mantém cursor 0; avanço ocorre dentro da transação junto do `CardReview`.
- `decks#show?ready_to_review=true`: retorna a definição da vista atual no campo
  `definition`; cursor inexistente cai na original sem quebrar.
- `cards#index`, `decks#index`, `decks#show` sem flag: **não** vazam
  alternativas (teste explícito da ocultação).

### Bordas

- card sem alternativas → comportamento idêntico ao atual em todos os fluxos;
- cursor fora do intervalo → wrap para a original;
- nada no fluxo de geração levanta erro por causa de alternativas.

## Fora de escopo (YAGNI)

- Endpoints para criar/editar/listar alternativas manualmente.
- Alternativas para cards criados manualmente (modelo já suporta, mas sem UI/endpoint agora).
- Exibir todas as alternativas de uma vez (decidido: uma por revisão).
- Decks ocultos reais.
