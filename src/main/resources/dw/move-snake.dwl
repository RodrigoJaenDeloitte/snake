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

// Prevent moving back into neck
var myNeckDirection = 
    if (neck.x < head.x) "left"
    else if (neck.x > head.x) "right"
    else if (neck.y < head.y) "down"
    else "up"

// Position calculation
fun newPos(move) =
    move match {
        case "up"    -> { x: head.x,     y: head.y + 1 }
        case "down"  -> { x: head.x,     y: head.y - 1 }
        case "left"  -> { x: head.x - 1, y: head.y }
        case "right" -> { x: head.x + 1, y: head.y }
    }

// Bounds check
fun isInside(pos) =
    pos.x >= 0 and pos.x < board.width and
    pos.y >= 0 and pos.y < board.height

// Check if position collides with self or other snakes
fun isSnake(pos) =
    (body ++ flatten(allSnakes map ((s) -> s.body))) any ((s) -> s.x == pos.x and s.y == pos.y)

// Head-to-head risk (avoid if enemy head is near and >= my size)
fun isHeadToHeadRisk(pos) =
    allSnakes any ((s) -> 
        sizeOf(s.body) >= myLength and
        manhattan(s.body[0], pos) <= 1
    )

// Manhattan distance
fun manhattan(a, b) = abs(a.x - b.x) + abs(a.y - b.y)

// Flood fill with visited tracking (improved safety space eval)
fun flood(pos, visited = [], depth = 5): Number =
    if (depth == 0 or not isInside(pos) or isSnake(pos) or (visited any ((v) -> v.x == pos.x and v.y == pos.y))) 
        0
    else 
        1 + sum(
            moves map ((m) -> 
                flood(newPosFrom(pos, m), visited ++ [pos], depth - 1)
            )
        )

fun newPosFrom(origin, move) =
    move match {
        case "up"    -> { x: origin.x,     y: origin.y + 1 }
        case "down"  -> { x: origin.x,     y: origin.y - 1 }
        case "left"  -> { x: origin.x - 1, y: origin.y }
        case "right" -> { x: origin.x + 1, y: origin.y }
    }

// Safe move: on board, not hitting snake, not reversing, not near bigger head
fun isSafe(move) =
    move != myNeckDirection and
    isInside(newPos(move)) and
    not isSnake(newPos(move)) and
    not isHeadToHeadRisk(newPos(move))

var safeMoves = moves filter isSafe

// Prioritize aggressive moves to eliminate smaller snakes
fun killsSmaller(move) =
    allSnakes any ((s) -> 
        sizeOf(s.body) < myLength and
        manhattan(newPos(move), s.body[0]) == 1
    )

var attackMoves = safeMoves filter killsSmaller

// Smart food seeking (only if safe and efficient)
fun isSafeFoodTarget(f) =
    allSnakes all ((s) -> manhattan(s.body[0], f) >= manhattan(head, f))

var closestFood = 
    if (isEmpty(food)) null
    else 
        (food filter isSafeFoodTarget) 
        reduce ((f1, f2) -> if (manhattan(head, f1) < manhattan(head, f2)) f1 else f2) default null

var towardFoodMoves = 
    if (closestFood == null) []
    else
        safeMoves filter ((m) -> 
            manhattan(newPos(m), closestFood) < manhattan(head, closestFood)
        )

// Evaluate space per move (avoid traps)
var spacePerMove = 
    safeMoves map ((m) -> {
        move: m,
        space: flood(newPos(m))
    })

var maxSpace = max(spacePerMove map $.space)
var bestSpaceMoves = spacePerMove filter ((s) -> s.space == maxSpace) map $.move

// Final Spartan decision
var nextMove = 
    if (!isEmpty(attackMoves)) 
        attackMoves[randomInt(sizeOf(attackMoves))]
    else if (!isEmpty(towardFoodMoves) and myLength < 20) 
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
    shout: "SPARTAN: Striking with honor to the $(nextMove)!"
}
