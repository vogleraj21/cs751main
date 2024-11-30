import pygame
import pandas as pd
import ast

# Load the data from the CSV file
file_path = "traffic_samples.csv"  # Adjust this path if needed
traffic_data = pd.read_csv(file_path)
traffic_data["Queues"] = traffic_data["Queues"].apply(ast.literal_eval)  # Convert strings to lists

# Initialize Pygame
pygame.init()

# Screen dimensions
screen_width, screen_height = 600, 600
screen = pygame.display.set_mode((screen_width, screen_height))
pygame.display.set_caption("4-Way Traffic Light Simulation")

# Colors
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
RED = (255, 0, 0)
GREEN = (0, 255, 0)
GRAY = (200, 200, 200)

# Clock and timing
clock = pygame.time.Clock()
time_step_duration = 200  # 200 milliseconds per time step

# Map light index to positions
light_positions = {
    1: (screen_width // 2, screen_height // 4),  # North
    2: (3 * screen_width // 4, screen_height // 2),  # East
    3: (screen_width // 2, 3 * screen_height // 4),  # South
    4: (screen_width // 4, screen_height // 2),  # West
}

# Map queue positions
queue_positions = {
    1: (screen_width // 2, screen_height // 4 - 50),  # North queue
    2: (3 * screen_width // 4 + 50, screen_height // 2),  # East queue
    3: (screen_width // 2, 3 * screen_height // 4 + 50),  # South queue
    4: (screen_width // 4 - 50, screen_height // 2),  # West queue
}

font = pygame.font.Font(None, 36)
small_font = pygame.font.Font(None, 24)

# Track state for "+1" and "-1"
fade_effects = {i: {"text": "", "timer": 0} for i in range(1, 5)}

def draw_traffic_lights(green_light):
    """Draw traffic lights in a diamond shape."""
    for i in range(1, 5):
        x, y = light_positions[i]
        color = GREEN if i == green_light else RED
        pygame.draw.circle(screen, color, (x, y), 20)

def draw_queue_numbers():
    """Draw the number of cars in each queue."""
    for i, (x, y) in queue_positions.items():
        num_cars = queues[i - 1]
        text = font.render(str(num_cars), True, BLACK)
        text_rect = text.get_rect(center=(x, y))
        screen.blit(text, text_rect)

        # Draw fade effects for "+1" or "-1"
        if fade_effects[i]["timer"] > 0:
            color = RED if fade_effects[i]["text"] == "+1" else GREEN
            effect_text = small_font.render(fade_effects[i]["text"], True, color)
            effect_rect = effect_text.get_rect(center=(x + 15, y - 15))
            screen.blit(effect_text, effect_rect)
            fade_effects[i]["timer"] -= 1

# Simulation loop
running = True
current_step = 0
previous_queues = [0, 0, 0, 0]

while running:
    screen.fill(WHITE)
    
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    # Get current data
    current_data = traffic_data.iloc[current_step]
    green_light = current_data["GreenLight"]
    queues = current_data["Queues"]

    # Compare queues to detect changes
    for i in range(1, 5):
        diff = queues[i - 1] - previous_queues[i - 1]
        if diff > 0:
            fade_effects[i] = { "text": "+1", "timer": 3 }
        elif diff < 0 and i == green_light:
            fade_effects[i] = { "text": "-1", "timer": 3 }

    # Update previous queues
    previous_queues = queues[:]

    # Draw traffic lights and queues
    draw_traffic_lights(green_light)
    draw_queue_numbers()

    # Update display
    pygame.display.flip()
    
    # Wait for the next time step
    clock.tick(1000 // time_step_duration)
    
    # Advance to the next step
    current_step = (current_step + 1) % len(traffic_data)

pygame.quit()
