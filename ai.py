import pygame
import random
import math

# Initialize Pygame
pygame.init()

# Screen dimensions
screen_width = 800
screen_height = 600
screen = pygame.display.set_mode((screen_width, screen_height))
pygame.display.set_caption("Human vs AI - Endboss Showdown")

# Colors
WHITE = (255, 255, 255)
RED = (255, 0, 0)
GREEN = (0, 255, 0)
BLACK = (0, 0, 0)

# Player settings
player_size = 50
player_x = screen_width // 2
player_y = screen_height // 2
player_speed = 5

# AI settings
ai_size = 50
ai_x = random.randint(0, screen_width - ai_size)
ai_y = random.randint(0, screen_height - ai_size)
ai_speed = 3

# Clock for controlling frame rate
clock = pygame.time.Clock()

# Font for displaying text
font = pygame.font.SysFont("Arial", 32)

# Function to draw the player
def draw_player(x, y):
    pygame.draw.rect(screen, GREEN, (x, y, player_size, player_size))

# Function to draw the AI
def draw_ai(x, y):
    pygame.draw.rect(screen, RED, (x, y, ai_size, ai_size))

# Function to move AI towards player (simple AI)
def move_ai(ai_x, ai_y, player_x, player_y):
    dx = player_x - ai_x
    dy = player_y - ai_y
    distance = math.sqrt(dx**2 + dy**2)
    if distance != 0:
        dx /= distance
        dy /= distance
    ai_x += dx * ai_speed
    ai_y += dy * ai_speed
    return ai_x, ai_y

# Game loop
running = True
while running:
    screen.fill(WHITE)
    
    # Event handling
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    # Key presses for player movement
    keys = pygame.key.get_pressed()
    if keys[pygame.K_LEFT]:
        player_x -= player_speed
    if keys[pygame.K_RIGHT]:
        player_x += player_speed
    if keys[pygame.K_UP]:
        player_y -= player_speed
    if keys[pygame.K_DOWN]:
        player_y += player_speed

    # AI movement
    ai_x, ai_y = move_ai(ai_x, ai_y, player_x, player_y)

    # Check for collision
    if abs(player_x - ai_x) < player_size and abs(player_y - ai_y) < player_size:
        text = font.render("Game Over! AI Wins!", True, BLACK)
        screen.blit(text, (screen_width // 2 - text.get_width() // 2, screen_height // 2))
        pygame.display.update()
        pygame.time.delay(2000)
        running = False
    
    # Draw player and AI
    draw_player(player_x, player_y)
    draw_ai(ai_x, ai_y)

    # Update screen
    pygame.display.update()
    
    # Control the game speed (FPS)
    clock.tick(60)

# Quit Pygame
pygame.quit()
