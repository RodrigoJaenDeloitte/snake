%dw 2.0
output application/json

var you = payload.you
var head = you.body[0]
var neck = you.body[1]
var body = you.body
var bodyTail = body[1 to -1]
var board = payload.board
var food = board.food default []
var otherSnakes = board.snakes filter (s) -> s.id != you.id

var directions = ["up", "down", "left", "right"]

var opposite = 
    if (neck.x < head.x) "right"
    else if (neck.x > head.x) "left"
    else if (neck.y < head.y) "up"
    else "down"

fun newPos(pos, dir) =
    dir match {
        case "up"    -> { x: pos.x,     y: pos.y + 1 }
        case "down"  -> { x: pos.x,     y: pos.y - 1 }
        case "left"  -> { x: pos.x - 1, y: pos.y }
        case "right" -> { x: pos.x + 1, y: pos.y }
    }

fun isInside(pos) =
    pos.x >= 0 and pos.x < board.width and
    pos.y >= 0 and pos.y < board.height

fun isSelfCollision(pos) =
    sizeOf(bodyTail filter (b) -> b.x == pos.x and b.y == pos.y) > 0

fun isOtherSnakeCollision(pos) =
    sizeOf(
        otherSnakes filter (s) ->
            sizeOf(s.body filter (b) -> b.x == pos.x and b.y == pos.y) > 0
    ) > 0

fun isSafe(dir) =
    do {
        var pos = newPos(head, dir)
        ---
        dir != opposite and
        isInside(pos) and
        not isSelfCollision(pos) and
        not isOtherSnakeCollision(pos)
    }

fun manhattan(a, b) = abs(a.x - b.x) + abs(a.y - b.y)

var closestFood =
    if (!isEmpty(food)) 
        reduce(food, (a, b) -> if (manhattan(head, a) < manhattan(head, b)) a else b)
    else 
        null

var safeMoves = directions filter (d) -> isSafe(d)

var foodMoves =
    if (closestFood == null) []
    else
        safeMoves filter (d) -> 
            manhattan(newPos(head, d), closestFood) < manhattan(head, closestFood)

fun canAttack(dir) =
    do {
        var target = newPos(head, dir)
        ---
        sizeOf(
            otherSnakes filter (s) ->
                sizeOf(s.body) < sizeOf(body) and
                manhattan(s.body[0], target) == 1
        ) > 0
    }

var attackMoves = safeMoves filter (d) -> canAttack(d)

var nextMove =
    if (!isEmpty(attackMoves)) 
        attackMoves[randomInt(sizeOf(attackMoves))]
    else if (!isEmpty(foodMoves)) 
        foodMoves[randomInt(sizeOf(foodMoves))]
    else if (!isEmpty(safeMoves))
        safeMoves[randomInt(sizeOf(safeMoves))]
    else
        (directions filter (d) -> isInside(newPos(head, d)))[0] default "up"

---
{
    move: nextMove,
    shout: "¡Spartano al ataque por la dirección $(nextMove)!"
}
