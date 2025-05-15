%dw 2.0
output application/json

// Helper: Get all possible moves
fun allMoves() = ["up", "down", "left", "right"]

// Helper: Get new head position for a move
fun moveHead(head, move) =
    head ++
    (move match {
        case "up"    -> { y: head.y + 1 }
        case "down"  -> { y: head.y - 1 }
        case "left"  -> { x: head.x - 1 }
        case "right" -> { x: head.x + 1 }
        else         -> {}
    })

// Helper: Check if position is inside the board
fun isInsideBoard(pos, board) =
    pos.x >= 0 and pos.x < board.width and pos.y >= 0 and pos.y < board.height

// Helper: Check if position collides with any snake
fun isSafe(pos, snakes) =
    not ( sizeOf(snakes flatMap ((s) -> s.body) filter ((b) -> b.x == pos.x and b.y == pos.y)) > 0)

// Helper: Find all safe directions
fun findSafeDirections(data) =
    allMoves() filter ((m) -> 
        do {
            var newHead = moveHead(data.you.head, m)
            ---
            isInsideBoard(newHead, data.board) and isSafe(newHead, data.board.snakes)
        }
    )

// Helper: Get next direction based on current fill direction
fun getNextDirection(currentDirection, safeDirections, myHead, board) =
    currentDirection match {
        case "right" -> 
            if (myHead.x < board.width - 1 and (safeDirections contains "right")) "right"
            else if (myHead.y < board.height - 1 and (safeDirections contains "up")) "up"
            else null
        case "left" -> 
            if (myHead.x > 0 and (safeDirections contains "left")) "left"
            else if (myHead.y < board.height - 1 and (safeDirections contains "up")) "up"
            else null
        case "down-right" ->
            if (myHead.x < board.width - 1 and (safeDirections contains "right")) "right"
            else if (myHead.y > 0 and (safeDirections contains "down")) "down"
            else null
        case "down-left" ->
            if (myHead.x > 0 and (safeDirections contains "left")) "left"
            else if (myHead.y > 0 and (safeDirections contains "down")) "down"
            else null
        else -> null
    }

// Main ping-pong flood fill logic
fun pingPongFloodFill(data, lastDirection) = do {
    var myHead = data.you.head
    var board = data.board
    var safeDirections = findSafeDirections(data)
    var direction = getNextDirection(lastDirection, safeDirections, myHead, board)
    ---
    if (direction != null) direction
    else 
        // Switch direction if blocked or at border
        lastDirection match {
            case "right" -> if (safeDirections contains "left") "left" else if (safeDirections contains "up") "up" else if (safeDirections contains "down") "down" else "up"
            case "left" -> if (safeDirections contains "right") "right" else if (safeDirections contains "up") "up" else if (safeDirections contains "down") "down" else "up"
            case "down-right" -> if (safeDirections contains "down-left") "down-left" else if (safeDirections contains "down") "down" else if (safeDirections contains "right") "right" else "up"
            case "down-left" -> if (safeDirections contains "down-right") "down-right" else if (safeDirections contains "down") "down" else if (safeDirections contains "left") "left" else "up"
            else -> if (sizeOf(safeDirections)  > 0) safeDirections[0] else "up"
        }
}

// Main function
fun chooseDirection(data) = do {
    var lastDirection = (data.shout default "right")
    var direction = pingPongFloodFill(data, lastDirection)
    ---
    direction
}

---
{
    move: chooseDirection(payload),
    shout: "move" // Save the last direction in shout
}