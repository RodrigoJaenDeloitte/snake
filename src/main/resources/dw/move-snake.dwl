%dw 2.0
output application/json

var body = payload.you.body
var board = payload.board
var head = body[0]
var neck = body[1]
var food = board.food
var allSnakes = board.snakes filter (s) -> s.id != payload.you.id
var myLength = sizeOf(body)

var moves = ["up", "down", "left", "right"]

// Posición resultante de cada movimiento desde una posición
fun newPosFrom(pos, move) =
    move match {
        case "up"    -> { x: pos.x,     y: pos.y + 1 }
        case "down"  -> { x: pos.x,     y: pos.y - 1 }
        case "left"  -> { x: pos.x - 1, y: pos.y }
        case "right" -> { x: pos.x + 1, y: pos.y }
    }

var myNeckDirection = 
    if (neck.x < head.x) "left"
    else if (neck.x > head.x) "right"
    else if (neck.y < head.y) "down"
    else "up"

// Verifica si una posición está dentro del tablero
fun isInside(pos) =
    pos.x >= 0 and pos.x < board.width and
    pos.y >= 0 and pos.y < board.height

// Verifica si hay colisión con alguna serpiente (incluye la propia)
fun isSnake(pos) =
    (body ++ flatten(allSnakes map ((s) -> s.body))) any ((s) -> s.x == pos.x and s.y == pos.y)

// Verifica si una posición está cerca de una cabeza de serpiente igual o más grande
fun isHeadToHeadRisk(pos) =
    allSnakes any ((s) -> 
        sizeOf(s.body) >= myLength and
        manhattan(s.body[0], pos) <= 1
    )

fun manhattan(a, b) = abs(a.x - b.x) + abs(a.y - b.y)

// Flood Fill para evaluar el espacio libre
fun flood(pos, visited = [], depth = 5): Number =
    if (
        depth == 0 or 
        not isInside(pos) or 
        isSnake(pos) or 
        (visited any ((v) -> v.x == pos.x and v.y == pos.y))
    ) 
        0
    else 
        1 + sum(
            moves map ((m) -> 
                flood(newPosFrom(pos, m), visited ++ [pos], depth - 1)
            )
        )

// Verifica si moverse a esa dirección es seguro
fun isSafe(move) =
    move != myNeckDirection and
    do {
        var pos = newPosFrom(head, move)
        ---
        isInside(pos) and
        not isSnake(pos) and
        not isHeadToHeadRisk(pos)
    }

var safeMoves = moves filter isSafe

// Atacar serpientes más pequeñas
fun canAttack(move) =
    do {
        var pos = newPosFrom(head, move)
        ---
        allSnakes any ((s) -> 
            sizeOf(s.body) < myLength and
            manhattan(pos, s.body[0]) == 1
        )
    }

var attackMoves = safeMoves filter canAttack

// Evaluar comida segura
fun isSafeFoodTarget(f) =
    allSnakes all ((s) -> manhattan(s.body[0], f) >= manhattan(head, f))

var closestFood = 
    if (isEmpty(food)) null
    else 
        (food filter isSafeFoodTarget) 
        reduce ((f1, f2) -> 
            if (manhattan(head, f1) < manhattan(head, f2)) f1 else f2
        ) default null

var towardFoodMoves = 
    if (closestFood == null) []
    else
        safeMoves filter ((m) -> 
            manhattan(newPosFrom(head, m), closestFood) < manhattan(head, closestFood)
        )

// Evaluar espacio disponible por cada movimiento
var moveSpace =
    safeMoves map ((m) -> {
        move: m,
        space: flood(newPosFrom(head, m))
    })

var maxSpace = max(moveSpace map $.space)
var bestMovesBySpace = moveSpace filter ((m) -> m.space == maxSpace) map $.move

// DECISIÓN FINAL DE MOVIMIENTO
var nextMove = 
    if (!isEmpty(attackMoves)) 
        attackMoves[randomInt(sizeOf(attackMoves))]
    else if (!isEmpty(towardFoodMoves) and myLength < 20)
        towardFoodMoves[randomInt(sizeOf(towardFoodMoves))]
    else if (!isEmpty(bestMovesBySpace)) 
        bestMovesBySpace[randomInt(sizeOf(bestMovesBySpace))]
    else if (!isEmpty(safeMoves))
        safeMoves[randomInt(sizeOf(safeMoves))]
    else 
        // Si no hay movimientos seguros, elegir uno dentro del tablero aunque sea arriesgado
        (moves filter ((m) -> isInside(newPosFrom(head, m))))[0] default "up"

---
{
    move: nextMove,
    shout: "¡Spartano avanza hacia el $(nextMove)! ¡Inmortal en batalla!"
}
