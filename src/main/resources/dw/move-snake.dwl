%dw 2.0
output application/json

// Variables principales
var you = payload.you
var head = you.body[0]
var neck = you.body[1]
var body = you.body
var bodyTail = body[1 to -1] // para evitar colisionar con la cabeza
var board = payload.board
var food = board.food default []
var otherSnakes = board.snakes filter (s) -> s.id != you.id

// Direcciones posibles
var directions = ["up", "down", "left", "right"]

// Movimiento inverso (no volver al cuello)
var opposite = 
    if (neck.x < head.x) "right"
    else if (neck.x > head.x) "left"
    else if (neck.y < head.y) "up"
    else "down"

// Calcula nueva posición según movimiento
fun newPos(pos, dir) =
    dir match {
        case "up"    -> { x: pos.x,     y: pos.y + 1 }
        case "down"  -> { x: pos.x,     y: pos.y - 1 }
        case "left"  -> { x: pos.x - 1, y: pos.y }
        case "right" -> { x: pos.x + 1, y: pos.y }
    }

// Verifica si está dentro del mapa
fun isInside(pos) =
    pos.x >= 0 and pos.x < board.width and
    pos.y >= 0 and pos.y < board.height

// Verifica si se choca consigo mismo
fun isSelfCollision(pos) =
    bodyTail any (b) -> b.x == pos.x and b.y == pos.y

// Verifica si se choca con otro snake
fun isOtherSnakeCollision(pos) =
    otherSnakes any (s) -> 
        s.body any (b) -> b.x == pos.x and b.y == pos.y

// Evalúa si moverse a esa dirección es seguro
fun isSafe(dir) =
    do {
        var pos = newPos(head, dir)
        ---
        dir != opposite and
        isInside(pos) and
        not isSelfCollision(pos) and
        not isOtherSnakeCollision(pos)
    }

// Distancia Manhattan
fun manhattan(a, b) = abs(a.x - b.x) + abs(a.y - b.y)

// Encuentra comida más cercana
var closestFood =
    if (!isEmpty(food)) 
        food reduce ((a, b) -> if (manhattan(head, a) < manhattan(head, b)) a else b)
    else 
        null

// Movimientos seguros
var safeMoves = directions filter (d) -> isSafe(d)

// Si hay comida, elige movimientos que lo acerquen
var foodMoves =
    if (closestFood == null) []
    else
        safeMoves filter (d) -> 
            manhattan(newPos(head, d), closestFood) < manhattan(head, closestFood)

// Buscar posibilidad de ataque (cabeza enemiga cerca y más pequeña)
fun canAttack(dir) =
    do {
        var target = newPos(head, dir)
        ---
        otherSnakes any (s) -> 
            sizeOf(s.body) < sizeOf(body) and
            manhattan(s.body[0], target) == 1
    }

var attackMoves = safeMoves filter (d) -> canAttack(d)

// Elegir el mejor movimiento
var nextMove =
    if (!isEmpty(attackMoves)) 
        attackMoves[randomInt(sizeOf(attackMoves))]
    else if (!isEmpty(foodMoves)) 
        foodMoves[randomInt(sizeOf(foodMoves))]
    else if (!isEmpty(safeMoves))
        safeMoves[randomInt(sizeOf(safeMoves))]
    else
        // Último recurso: cualquier dirección dentro del mapa (aunque no sea segura)
        (directions filter (d) -> isInside(newPos(head, d)))[0] default "up"

---
{
    move: nextMove,
    shout: "¡Spartano al ataque por la dirección $(nextMove)!"
}
