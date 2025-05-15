%dw 2.0
output application/json

// Declare functions
fun isSafeDirection(direction, data) = do {
    var myHead = data.you.head
    var board = data.board
    var myBody = data.you.body
    
    // Check if direction would go off the map
    var offMap = direction match {
        case "up" -> myHead.y >= board.height - 1
        case "down" -> myHead.y <= 0
        case "left" -> myHead.x <= 0
        case "right" -> myHead.x >= board.width - 1
        else -> false
    }
    
    // Calculate next position based on direction
    var nextPos = direction match {
        case "up" -> { x: myHead.x, y: myHead.y + 1 }
        case "down" -> { x: myHead.x, y: myHead.y - 1 }
        case "left" -> { x: myHead.x - 1, y: myHead.y }
        case "right" -> { x: myHead.x + 1, y: myHead.y }
        else -> myHead
    }
    
    // Check for self-collision
    var selfCollision = myBody some (segment) -> 
        segment.x == nextPos.x and segment.y == nextPos.y
    
    // Check for collision with other snakes
    var snakeCollision = board.snakes some (snake) -> 
        snake.body some (segment) -> 
            segment.x == nextPos.x and segment.y == nextPos.y
    
    // Check for head-to-head collision with larger snakes
    var headCollision = board.snakes some (snake) -> do {
        var enemyHead = snake.head
        var enemyLength = sizeOf(snake.body)
        var myLength = sizeOf(data.you.body)
        
        // Only consider snakes that aren't us
        var notUs = snake.id != data.you.id
        
        // Calculate potential next position of enemy head
        var enemyNextPos = {
            up: { x: enemyHead.x, y: enemyHead.y + 1 },
            down: { x: enemyHead.x, y: enemyHead.y - 1 },
            left: { x: enemyHead.x - 1, y: enemyHead.y },
            right: { x: enemyHead.x + 1, y: enemyHead.y }
        }
        
        // Check if our next position would collide with enemy's potential next position
        // AND enemy is larger or same size
        var collision = (
            enemyNextPos.up.x == nextPos.x and enemyNextPos.up.y == nextPos.y or
            enemyNextPos.down.x == nextPos.x and enemyNextPos.down.y == nextPos.y or
            enemyNextPos.left.x == nextPos.x and enemyNextPos.left.y == nextPos.y or
            enemyNextPos.right.x == nextPos.x and enemyNextPos.right.y == nextPos.y
        )
        
        // Return combined conditions
        (notUs and collision and (enemyLength >= myLength))
    }
    // Return true if direction is safe
    not (offMap or selfCollision or snakeCollision or headCollision)
}

// Function to find safe directions
fun findSafeDirections(data) = do {
    var directions = ["up", "down", "left", "right"]
    directions filter ((direction) -> isSafeDirection(direction, data))
}

fun findFoodDirection(data, safeDirections) = do {
    var myHead = data.you.head
    var foods = data.board.food

    if (isEmpty(foods) or isEmpty(safeDirections)) 
        null
    else do {
        var foodDistances = foods map (food) -> {
            food: food,
            distance: abs(myHead.x - food.x) + abs(myHead.y - food.y)
        }
        var sortedFoods = foodDistances orderBy $.distance

        if (isEmpty(sortedFoods)) 
            null 
        else do {
            var closestFood = sortedFoods[0].food
            var dx = closestFood.x - myHead.x
            var dy = closestFood.y - myHead.y

            if (abs(dx) >= abs(dy)) {
                if (dx > 0 and safeDirections contains "right") {
                    "right"
                }
                else if (dx < 0 and safeDirections contains "left") {
                    "left"
                }
                else if (dy > 0 and safeDirections contains "up") {
                    "up"
                }
                else if (dy < 0 and safeDirections contains "down") {
                    "down"
                }
                else {
                    null
                }
            } else {
                if (dy > 0 and safeDirections contains "up") {
                    "up"
                }
                else if (dy < 0 and safeDirections contains "down") {
                    "down"
                }
                else if (dx > 0 and safeDirections contains "right") {
                    "right"
                }
                else if (dx < 0 and safeDirections contains "left") {
                    "left"
                }
                else {
                    null
                }
            }
        }
    }
}

// Function to hunt smaller snakes
fun huntSmallerSnakes(data, safeDirections) = do {
    var myHead = data.you.head
    var myLength = sizeOf(data.you.body)
    
    // Find smaller snakes
    var smallerSnakes = data.board.snakes filter (snake) -> 
        snake.id != data.you.id and sizeOf(snake.body) < myLength
    
    if (isEmpty(smallerSnakes) or isEmpty(safeDirections))
        null
    else do {
        // Calculate distance to each smaller snake's head
        var snakeDistances = smallerSnakes map (snake) -> {
            snake: snake,
            distance: abs(myHead.x - snake.head.x) + abs(myHead.y - snake.head.y)
        }
        
        // Sort by distance (closest first)
        var sortedSnakes = snakeDistances orderBy $.distance
        
        // Only consider snakes that are close enough
        var closeSnakes = sortedSnakes filter (item) -> item.distance <= 5
        
        if (isEmpty(closeSnakes))
            null
        else do {
            var targetSnake = closeSnakes[0].snake
            var dx = targetSnake.head.x - myHead.x
            var dy = targetSnake.head.y - myHead.y

            if (abs(dx) >= abs(dy)) {
                if (dx > 0 and safeDirections contains "right")
                    "right"
                else if (dx < 0 and safeDirections contains "left")
                    "left"
                else if (dy > 0 and safeDirections contains "up")
                    "up"
                else if (dy < 0 and safeDirections contains "down")
                    "down"
                else
                    null
            } else {
                if (dy > 0 and safeDirections contains "up")
                    "up"
                else if (dy < 0 and safeDirections contains "down")
                    "down"
                else if (dx > 0 and safeDirections contains "right")
                    "right"
                else if (dx < 0 and safeDirections contains "left")
                    "left"
                else
                    null
            }
        }
    }
}

// Main function to choose direction
fun chooseDirection(data) = do {
    var safeDirections = findSafeDirections(data)
    var myHealth = data.you.health
    
    if (isEmpty(safeDirections))
        "up" // Desperate move if no safe directions
    else do {
        var direction = null
        
        // Priority 5: Try to kill smaller snakes if health is good
        if (myHealth > 50) {
            direction = huntSmallerSnakes(data, safeDirections)
        }
        
        // Priority 3: Find food if health is low or no smaller snakes to hunt
        if (direction == null) {
            direction = findFoodDirection(data, safeDirections)
        }
        
        // If no specific direction needed, pick a random safe direction
        if (direction == null) {
            var randomIndex = random() * sizeOf(safeDirections) as Number as Number {format: "###0"}
            direction = safeDirections[randomIndex]
        }
        
        direction
    }
}

---
// Main function
{
    move: chooseDirection(payload),
    shout: "Voy a por ti"
}