# scenes/w0_f1.py
import pygame, random

class W0F1Life:
    """
    Challenge: houd het patroon 10 generaties in leven (geen uitsterving).
    Besturing:
      L-klik  : toggle cel
      R-klik  : run/pauze
      SPACE   : run/pauze
      N       : single step
      C       : clear
      R       : random seed
      ESC     : terug naar menu
    Succes → next_scene = 'w0_f2'
    """
    def __init__(self, services: dict):
        self.services = services
        self.done = False
        self.next_scene = None

        # grid
        self.cols, self.rows = 30, 18  # ~ 1280x720 met cel ±24-32 px
        self.cell = 24
        self.margin = 12
        self.run = False
        self.accum = 0.0
        self.step_every = 0.15  # s/generation

        self.grid = [[0]*self.cols for _ in range(self.rows)]
        # random startje (spaarzaam)
        for _ in range(80):
            r = random.randrange(self.rows); c = random.randrange(self.cols)
            self.grid[r][c] = 1

        self.generation = 0
        self.streak_alive = 0          # aaneengesloten generaties met >0 cellen
        self.target_streak = 10

    # ---------- helpers ----------
    def _rc_from_pos(self, pos):
        x, y = pos
        ox = self.margin; oy = self.margin
        x -= ox; y -= oy
        if x < 0 or y < 0: return None
        c = x // self.cell
        r = y // self.cell
        if 0 <= r < self.rows and 0 <= c < self.cols:
            return (r, c)
        return None

    def _count_alive(self, grid):
        return sum(sum(row) for row in grid)

    def _step(self, g):
        rows, cols = self.rows, self.cols
        nxt = [[0]*cols for _ in range(rows)]
        for r in range(rows):
            for c in range(cols):
                n = 0
                for dr in (-1,0,1):
                    for dc in (-1,0,1):
                        if dr==0 and dc==0: continue
                        rr = r+dr; cc = c+dc
                        if 0 <= rr < rows and 0 <= cc < cols:
                            n += g[rr][cc]
                if g[r][c]:
                    nxt[r][c] = 1 if (n==2 or n==3) else 0
                else:
                    nxt[r][c] = 1 if (n==3) else 0
        return nxt

    # ---------- io ----------
    def handle_event(self, e):
        if e.type == pygame.KEYDOWN:
            if e.key == pygame.K_ESCAPE:
                self.done = True; self.next_scene = 'scene_picker'
            elif e.key == pygame.K_SPACE:
                self.run = not self.run
            elif e.key == pygame.K_n:
                self.grid = self._step(self.grid); self.generation += 1
            elif e.key == pygame.K_c:
                self.grid = [[0]*self.cols for _ in range(self.rows)]
                self.generation = 0; self.streak_alive = 0
            elif e.key == pygame.K_r:
                self.grid = [[0]*self.cols for _ in range(self.rows)]
                for _ in range(80):
                    r = random.randrange(self.rows); c = random.randrange(self.cols)
                    self.grid[r][c] = 1
                self.generation = 0; self.streak_alive = 0

        elif e.type == pygame.MOUSEBUTTONDOWN:
            rc = self._rc_from_pos(e.pos)
            if rc:
                r, c = rc
                if e.button == 1:   # toggle
                    self.grid[r][c] = 0 if self.grid[r][c] else 1
                elif e.button == 3: # run/pause
                    self.run = not self.run

    def update(self, dt):
        if not self.run: return
        self.accum += dt
        if self.accum >= self.step_every:
            self.accum = 0.0
            self.grid = self._step(self.grid)
            self.generation += 1
            alive = self._count_alive(self.grid)
            if alive > 0:
                self.streak_alive += 1
                if self.streak_alive >= self.target_streak:
                    self.done = True
                    self.next_scene = 'w0_f2'
            else:
                # uitgestorven → streak resetten
                self.streak_alive = 0

    def draw(self, screen):
        w, h = screen.get_size()
        screen.fill((18,18,22))
        ox = self.margin; oy = self.margin
        for r in range(self.rows):
            for c in range(self.cols):
                rect = pygame.Rect(ox + c*self.cell, oy + r*self.cell, self.cell-1, self.cell-1)
                if self.grid[r][c]:
                    pygame.draw.rect(screen, (240,240,240), rect)
                else:
                    pygame.draw.rect(screen, (40,40,48), rect, 1)

        try: font = pygame.font.SysFont('consolas', 26)
        except: font = pygame.font.Font(None, 26)

        info = f"W0 • F1 — Life  |  gen={self.generation}  alive-streak={self.streak_alive}/{self.target_streak}  (Space=run/pause, N=step, R=random, C=clear)"
        screen.blit(font.render(info, True, (200,200,210)), (20, h-40))

    def on_snapshot(self, screen, when='final'):
        self.draw(screen)
