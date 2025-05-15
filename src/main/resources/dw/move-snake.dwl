%dw 2.0
output application/json

var body = payload.you.body
var board = payload.board
var head = body[0]
var neck = body[1]
var food = payload.board.food

var moves = ["up", "down", "left", "right"]

// Evitar retroceder hacia el cuello
var myNeckLocation = 
    if (neck.x < head.x) "left"
    else if (neck.x > head.x) "right"
    else if (neck.y < head.y) "down"
    else if (neck.y > head.y) "up"
    else ""

// Funciones de posición y movimiento
fun isInsideBoard(pos) =
    pos.x >= 0 and 
    pos.x < board.width and
    pos.y >= 0 and 
    pos.y < board.height

fun newPos(move) =
    move match {
        case "up"    -> { x: head.x,     y: head.y + 1 }
        case "down"  -> { x: head.x,     y: head.y - 1 }
        case "left"  -> { x: head.x - 1, y: head.y }
        case "right" -> { x: head.x + 1, y: head.y }
    }

// Funciones de detección de colisiones
fun isSnakeCollision(pos) = 
    sizeOf(body filter (segment) -> segment.x == pos.x and segment.y == pos.y) > 0

fun isOtherSnakeCollision(pos) = 
    sizeOf(payload.board.snakes filter (snake) -> 
        snake.id != payload.you.id and (
            sizeOf(snake.body filter (segment) -> 
                segment.x == pos.x and segment.y == pos.y
            ) > 0
        )
    ) > 0

// Detección de callejones sin salida
fun isDeadEnd(pos, depth) =
    if (depth == 0) false
    else
        sizeOf(moves filter (move) ->
            isSafeMove(move) and 
            not isDeadEnd(newPos(move), depth - 1)
        ) == 0

// Función de distancia Manhattan
fun manhattan(a, b) = abs(a.x - b.x) + abs(a.y - b.y)

// Control de territorio usando flood fill
fun floodFill(pos, depth) =
    if (depth == 0) 1
    else
        1 + sum(
            moves map (move) -> (
                if (isSafeMove(move)) 
                    floodFill(newPos(move), depth - 1)
                else 0
            )
        )

// Estrategias mejoradas
fun canEliminateSmallerSnake(pos) = 
    sizeOf(payload.board.snakes filter (snake) -> 
        snake.id != payload.you.id and 
        sizeOf(snake.body) < sizeOf(body) and
        sizeOf(snake.body filter (segment) -> 
            manhattan(pos, segment) == 1
        ) > 0
    ) > 0

fun isNearBiggerSnake(pos) =
    sizeOf(payload.board.snakes filter (snake) ->
        snake.id != payload.you.id and
        sizeOf(snake.body) >= sizeOf(body) and
        manhattan(snake.body[0], pos) <= 2
    ) > 0

fun isFoodSafe(foodPos) =
    sizeOf(payload.board.snakes filter (snake) ->
        snake.id != payload.you.id and
        manhattan(snake.body[0], foodPos) < manhattan(head, foodPos)
    ) == 0

// Movimientos seguros mejorados
fun isSafeMove(move) =
    (
        move != myNeckLocation and
        isInsideBoard(newPos(move)) and
        not isSnakeCollision(newPos(move)) and
        not isOtherSnakeCollision(newPos(move)) and
        not isDeadEnd(newPos(move), 3)
    )

var safeMoves = moves filter (move) -> isSafeMove(move)

// Búsqueda de comida mejorada
var closestFood = 
    if (isEmpty(food)) null
    else 
        food reduce ((f1, f2) -> 
            if (manhattan(head, f1) < manhattan(head, f2)) f1 else f2
        )

var towardFoodMoves = 
    if (closestFood == null) []
    else
        safeMoves filter (move) -> 
            manhattan(newPos(move), closestFood) < manhattan(head, closestFood) and
            isFoodSafe(closestFood)

var aggressiveMoves = 
    safeMoves filter (move) -> 
        canEliminateSmallerSnake(newPos(move))

// Movimientos por espacio disponible
var movesBySpace = 
    safeMoves map (move) -> {
        move: move,
        space: floodFill(newPos(move), 3)
    }

var bestSpaceMoves = 
    if (isEmpty(movesBySpace)) []
    else (
        movesBySpace filter (m) -> 
            m.space == max(movesBySpace map $.space)
    ) map $.move

// Lógica de decisión mejorada
var nextMove = 
    if (!isEmpty(aggressiveMoves) and not isNearBiggerSnake(head)) 
        aggressiveMoves[randomInt(sizeOf(aggressiveMoves))]
    else if (!isEmpty(towardFoodMoves) and sizeOf(body) < 20) 
        towardFoodMoves[randomInt(sizeOf(towardFoodMoves))]
    else if (!isEmpty(bestSpaceMoves))
        bestSpaceMoves[randomInt(sizeOf(bestSpaceMoves))]
    else if (!isEmpty(safeMoves))
        safeMoves[randomInt(sizeOf(safeMoves))]
    else 
        moves[randomInt(sizeOf(moves))]

---
{
    move: nextMove,
    shout: "¡Voy a $(nextMove) con mi estrategia mejorada!"
}