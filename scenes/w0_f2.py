# scenes/w0_f2.py
import pygame

class W0F2Still:
    """
    Challenge: maak een STILL-LIFE — patroon is exact gelijk aan de volgende generatie.
    Besturing:
      L-klik : toggle cel
      N      : single step (om te checken)
      SPACE  : run/pauze (langzaam)
      S      : 'solve check' — als next(grid)==grid → success
      C      : clear
      ESC    : terug
    Succes → next_scene='w0_f3'
    """
    def __init__(self, services: dict):
        self.services = services
        self.done = False
        self.next_scene = None

        self.cols, self.rows = 28, 16
        self.cell, self.margin = 26, 12
        self.grid = [[0]*self.cols for _ in range(self.rows)]
        self.run = False
        self.accum = 0.0
        self.step_every = 0.25
        self.generation = 0

    def _rc_from_pos(self, pos):
        x,y = pos; x-=self.margin; y-=self.margin
        if x<0 or y<0: return None
        c = x // self.cell; r = y // self.cell
        if 0<=r<self.rows and 0<=c<self.cols: return (r,c)
        return None

    def _step(self, g):
        rows, cols = self.rows, self.cols
        nxt = [[0]*cols for _ in range(rows)]
        for r in range(rows):
            for c in range(cols):
                n=0
                for dr in (-1,0,1):
                    for dc in (-1,0,1):
                        if dr==0 and dc==0: continue
                        rr=r+dr; cc=c+dc
                        if 0<=rr<rows and 0<=cc<cols: n+=g[rr][cc]
                nxt[r][c] = 1 if (n==3 or (g[r][c] and n==2)) else 0
        return nxt

    def _is_still_life(self):
        return self._step(self.grid) == self.grid

    def handle_event(self, e):
        if e.type == pygame.KEYDOWN:
            if e.key == pygame.K_ESCAPE:
                self.done = True; self.next_scene='scene_picker'
            elif e.key == pygame.K_SPACE:
                self.run = not self.run
            elif e.key == pygame.K_n:
                self.grid = self._step(self.grid); self.generation += 1
            elif e.key == pygame.K_c:
                self.grid = [[0]*self.cols for _ in range(self.rows)]
            elif e.key == pygame.K_s:  # solve check
                if self._is_still_life():
                    self.done = True; self.next_scene='w0_f3'
        elif e.type == pygame.MOUSEBUTTONDOWN and e.button == 1:
            rc = self._rc_from_pos(e.pos)
            if rc:
                r,c = rc; self.grid[r][c] = 0 if self.grid[r][c] else 1

    def update(self, dt):
        if not self.run: return
        self.accum += dt
        if self.accum >= self.step_every:
            self.accum = 0.0
            self.grid = self._step(self.grid); self.generation += 1

    def draw(self, screen):
        w,h = screen.get_size()
        screen.fill((15,15,18))
        ox=self.margin; oy=self.margin
        for r in range(self.rows):
            for c in range(self.cols):
                rect = pygame.Rect(ox+c*self.cell, oy+r*self.cell, self.cell-1, self.cell-1)
                if self.grid[r][c]:
                    pygame.draw.rect(screen, (235,235,235), rect)
                else:
                    pygame.draw.rect(screen, (50,50,58), rect, 1)

        try: font = pygame.font.SysFont('consolas', 26)
        except: font = pygame.font.Font(None, 26)
        ok = self._is_still_life()
        txt = f"W0 • F2 — Still life?  {'YES' if ok else 'NO'}   (S=check, Space=run/pause, N=step, C=clear)"
        screen.blit(font.render(txt, True, (200,200,210)), (20, h-40))

    def on_snapshot(self, screen, when='final'):
        self.draw(screen)
