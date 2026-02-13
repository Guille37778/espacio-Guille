final int TILE = 80;
final int BOARD_SIZE = TILE * 8;

Piece[][] board = new Piece[8][8];
ArrayList<Move> legalMoves = new ArrayList<Move>();

boolean whiteTurn = true;
int selectedRow = -1;
int selectedCol = -1;
String statusText = "Turno: Blancas";
PFont chessFont;

void setup() {
  size(BOARD_SIZE, BOARD_SIZE + 40);
  textAlign(CENTER, CENTER);
  chessFont = createFont("Arial Unicode MS", 52, true);
  textFont(chessFont);
  initBoard();
}

void draw() {
  background(20);
  drawBoard();
  drawPieces();
  drawHighlights();
  drawStatus();
}

void drawBoard() {
  for (int r = 0; r < 8; r++) {
    for (int c = 0; c < 8; c++) {
      if ((r + c) % 2 == 0) {
        fill(238, 238, 210);
      } else {
        fill(118, 150, 86);
      }
      noStroke();
      rect(c * TILE, r * TILE, TILE, TILE);
    }
  }
}

void drawPieces() {
  textFont(chessFont);
  for (int r = 0; r < 8; r++) {
    for (int c = 0; c < 8; c++) {
      Piece p = board[r][c];
      if (p != null) {
        fill(p.white ? color(250) : color(20));
        text(getPieceSymbol(p), c * TILE + TILE / 2, r * TILE + TILE / 2 + 2);
      }
    }
  }
}

void drawHighlights() {
  if (selectedRow >= 0 && selectedCol >= 0) {
    noFill();
    stroke(255, 215, 0);
    strokeWeight(4);
    rect(selectedCol * TILE, selectedRow * TILE, TILE, TILE);

    noStroke();
    for (Move m : legalMoves) {
      fill(30, 144, 255, 160);
      ellipse(m.toCol * TILE + TILE / 2, m.toRow * TILE + TILE / 2, TILE * 0.28, TILE * 0.28);
    }
  }
}

void drawStatus() {
  fill(30);
  rect(0, BOARD_SIZE, BOARD_SIZE, 40);
  fill(240);
  textFont(createFont("Arial", 18, true));
  text(statusText, BOARD_SIZE / 2, BOARD_SIZE + 20);
}

void mousePressed() {
  if (mouseY >= BOARD_SIZE) return;

  int c = mouseX / TILE;
  int r = mouseY / TILE;

  if (!inBounds(r, c)) return;

  if (selectedRow == -1) {
    trySelect(r, c);
    return;
  }

  Move chosen = findMove(selectedRow, selectedCol, r, c);
  if (chosen != null) {
    applyMove(chosen);
    endTurn();
  } else {
    if (board[r][c] != null && board[r][c].white == whiteTurn) {
      trySelect(r, c);
    } else {
      clearSelection();
    }
  }
}

void trySelect(int r, int c) {
  Piece p = board[r][c];
  if (p == null || p.white != whiteTurn) {
    clearSelection();
    return;
  }

  selectedRow = r;
  selectedCol = c;
  legalMoves = getLegalMovesForPiece(r, c);

  if (legalMoves.isEmpty()) {
    clearSelection();
  }
}

void clearSelection() {
  selectedRow = -1;
  selectedCol = -1;
  legalMoves.clear();
}

Move findMove(int fromR, int fromC, int toR, int toC) {
  for (Move m : legalMoves) {
    if (m.toRow == toR && m.toCol == toC) return m;
  }
  return null;
}

void endTurn() {
  clearSelection();
  whiteTurn = !whiteTurn;

  boolean inCheck = isKingInCheck(board, whiteTurn);
  ArrayList<Move> all = getAllLegalMoves(whiteTurn);

  if (all.isEmpty()) {
    if (inCheck) {
      statusText = "Jaque mate: " + (whiteTurn ? "Ganan negras" : "Ganan blancas");
    } else {
      statusText = "Tablas por ahogado";
    }
    noLoop();
  } else {
    statusText = "Turno: " + (whiteTurn ? "Blancas" : "Negras") + (inCheck ? " (Jaque)" : "");
  }
}

void applyMove(Move m) {
  Piece moving = board[m.fromRow][m.fromCol];

  if (m.castling) {
    board[m.toRow][m.toCol] = moving;
    board[m.fromRow][m.fromCol] = null;

    if (m.toCol == 6) {
      board[m.toRow][5] = board[m.toRow][7];
      board[m.toRow][7] = null;
      board[m.toRow][5].hasMoved = true;
    } else if (m.toCol == 2) {
      board[m.toRow][3] = board[m.toRow][0];
      board[m.toRow][0] = null;
      board[m.toRow][3].hasMoved = true;
    }
  } else {
    if (m.enPassant) {
      int capturedRow = moving.white ? m.toRow + 1 : m.toRow - 1;
      board[capturedRow][m.toCol] = null;
    }
    board[m.toRow][m.toCol] = moving;
    board[m.fromRow][m.fromCol] = null;
  }

  moving.hasMoved = true;

  if (moving.type == 'P' && (m.toRow == 0 || m.toRow == 7)) {
    moving.type = 'Q';
  }

  resetEnPassantFlags();
  if (moving.type == 'P' && abs(m.toRow - m.fromRow) == 2) {
    moving.justDoubleStepped = true;
  }
}

void initBoard() {
  for (int r = 0; r < 8; r++) {
    for (int c = 0; c < 8; c++) {
      board[r][c] = null;
    }
  }

  char[] back = { 'R', 'N', 'B', 'Q', 'K', 'B', 'N', 'R' };
  for (int c = 0; c < 8; c++) {
    board[0][c] = new Piece(back[c], false);
    board[1][c] = new Piece('P', false);
    board[6][c] = new Piece('P', true);
    board[7][c] = new Piece(back[c], true);
  }
}

ArrayList<Move> getAllLegalMoves(boolean forWhite) {
  ArrayList<Move> result = new ArrayList<Move>();
  for (int r = 0; r < 8; r++) {
    for (int c = 0; c < 8; c++) {
      Piece p = board[r][c];
      if (p != null && p.white == forWhite) {
        result.addAll(getLegalMovesForPiece(r, c));
      }
    }
  }
  return result;
}

ArrayList<Move> getLegalMovesForPiece(int r, int c) {
  Piece p = board[r][c];
  ArrayList<Move> pseudo = getPseudoMoves(board, r, c, true);
  ArrayList<Move> legal = new ArrayList<Move>();

  for (Move m : pseudo) {
    Piece[][] copy = cloneBoard(board);
    applyMoveOn(copy, m);
    if (!isKingInCheck(copy, p.white)) {
      legal.add(m);
    }
  }
  return legal;
}

ArrayList<Move> getPseudoMoves(Piece[][] state, int r, int c, boolean includeCastling) {
  ArrayList<Move> moves = new ArrayList<Move>();
  Piece p = state[r][c];
  if (p == null) return moves;

  if (p.type == 'P') {
    int dir = p.white ? -1 : 1;
    int startRow = p.white ? 6 : 1;

    if (inBounds(r + dir, c) && state[r + dir][c] == null) {
      moves.add(new Move(r, c, r + dir, c));
      if (r == startRow && state[r + 2 * dir][c] == null) {
        moves.add(new Move(r, c, r + 2 * dir, c));
      }
    }

    int[] dc = { -1, 1 };
    for (int offset : dc) {
      int nr = r + dir;
      int nc = c + offset;
      if (!inBounds(nr, nc)) continue;

      Piece target = state[nr][nc];
      if (target != null && target.white != p.white) {
        moves.add(new Move(r, c, nr, nc));
      }

      Piece side = state[r][nc];
      if (target == null && side != null && side.white != p.white && side.type == 'P' && side.justDoubleStepped) {
        Move ep = new Move(r, c, nr, nc);
        ep.enPassant = true;
        moves.add(ep);
      }
    }
  } else if (p.type == 'N') {
    int[][] jumps = {
      {-2, -1}, {-2, 1}, {-1, -2}, {-1, 2},
      {1, -2}, {1, 2}, {2, -1}, {2, 1}
    };
    for (int[] j : jumps) addIfValid(state, moves, r, c, r + j[0], c + j[1]);
  } else if (p.type == 'B') {
    addSliding(state, moves, r, c, new int[][]{{-1, -1}, {-1, 1}, {1, -1}, {1, 1}});
  } else if (p.type == 'R') {
    addSliding(state, moves, r, c, new int[][]{{-1, 0}, {1, 0}, {0, -1}, {0, 1}});
  } else if (p.type == 'Q') {
    addSliding(state, moves, r, c, new int[][]{{-1, -1}, {-1, 1}, {1, -1}, {1, 1}, {-1, 0}, {1, 0}, {0, -1}, {0, 1}});
  } else if (p.type == 'K') {
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc2 = -1; dc2 <= 1; dc2++) {
        if (dr == 0 && dc2 == 0) continue;
        addIfValid(state, moves, r, c, r + dr, c + dc2);
      }
    }

    if (includeCastling && !p.hasMoved && !isKingInCheck(state, p.white)) {
      // Enroque corto
      if (canCastle(state, p.white, true)) {
        Move m = new Move(r, c, r, 6);
        m.castling = true;
        moves.add(m);
      }
      // Enroque largo
      if (canCastle(state, p.white, false)) {
        Move m = new Move(r, c, r, 2);
        m.castling = true;
        moves.add(m);
      }
    }
  }

  return moves;
}

boolean canCastle(Piece[][] state, boolean white, boolean kingSide) {
  int row = white ? 7 : 0;
  int rookCol = kingSide ? 7 : 0;
  Piece king = state[row][4];
  Piece rook = state[row][rookCol];

  if (king == null || rook == null) return false;
  if (king.type != 'K' || rook.type != 'R') return false;
  if (king.hasMoved || rook.hasMoved) return false;

  int step = kingSide ? 1 : -1;
  int start = 4 + step;
  int end = kingSide ? 6 : 1;

  for (int c = start; c != end + step; c += step) {
    if (state[row][c] != null) return false;
  }

  int[] passSquares = kingSide ? new int[]{5, 6} : new int[]{3, 2};
  for (int c : passSquares) {
    Piece[][] copy = cloneBoard(state);
    copy[row][c] = copy[row][4];
    copy[row][4] = null;
    if (isKingInCheck(copy, white)) return false;
  }

  return true;
}

void addSliding(Piece[][] state, ArrayList<Move> moves, int r, int c, int[][] dirs) {
  Piece p = state[r][c];
  for (int[] d : dirs) {
    int nr = r + d[0];
    int nc = c + d[1];
    while (inBounds(nr, nc)) {
      if (state[nr][nc] == null) {
        moves.add(new Move(r, c, nr, nc));
      } else {
        if (state[nr][nc].white != p.white) {
          moves.add(new Move(r, c, nr, nc));
        }
        break;
      }
      nr += d[0];
      nc += d[1];
    }
  }
}

void addIfValid(Piece[][] state, ArrayList<Move> moves, int fromR, int fromC, int toR, int toC) {
  if (!inBounds(toR, toC)) return;
  Piece from = state[fromR][fromC];
  Piece to = state[toR][toC];
  if (to == null || to.white != from.white) {
    moves.add(new Move(fromR, fromC, toR, toC));
  }
}

boolean isKingInCheck(Piece[][] state, boolean whiteKing) {
  int kr = -1;
  int kc = -1;

  for (int r = 0; r < 8; r++) {
    for (int c = 0; c < 8; c++) {
      Piece p = state[r][c];
      if (p != null && p.type == 'K' && p.white == whiteKing) {
        kr = r;
        kc = c;
      }
    }
  }

  if (kr == -1) return true;

  for (int r = 0; r < 8; r++) {
    for (int c = 0; c < 8; c++) {
      Piece p = state[r][c];
      if (p != null && p.white != whiteKing) {
        ArrayList<Move> enemy = getPseudoMoves(state, r, c, false);
        for (Move m : enemy) {
          if (m.toRow == kr && m.toCol == kc) return true;
        }
      }
    }
  }
  return false;
}

Piece[][] cloneBoard(Piece[][] source) {
  Piece[][] copy = new Piece[8][8];
  for (int r = 0; r < 8; r++) {
    for (int c = 0; c < 8; c++) {
      if (source[r][c] != null) {
        copy[r][c] = source[r][c].clonePiece();
      }
    }
  }
  return copy;
}

void applyMoveOn(Piece[][] state, Move m) {
  Piece moving = state[m.fromRow][m.fromCol];
  if (moving == null) return;

  if (m.castling) {
    state[m.toRow][m.toCol] = moving;
    state[m.fromRow][m.fromCol] = null;

    if (m.toCol == 6) {
      state[m.toRow][5] = state[m.toRow][7];
      state[m.toRow][7] = null;
      if (state[m.toRow][5] != null) state[m.toRow][5].hasMoved = true;
    } else {
      state[m.toRow][3] = state[m.toRow][0];
      state[m.toRow][0] = null;
      if (state[m.toRow][3] != null) state[m.toRow][3].hasMoved = true;
    }
  } else {
    if (m.enPassant) {
      int capturedRow = moving.white ? m.toRow + 1 : m.toRow - 1;
      state[capturedRow][m.toCol] = null;
    }
    state[m.toRow][m.toCol] = moving;
    state[m.fromRow][m.fromCol] = null;
  }

  moving.hasMoved = true;

  if (moving.type == 'P' && (m.toRow == 0 || m.toRow == 7)) {
    moving.type = 'Q';
  }

  for (int r = 0; r < 8; r++) {
    for (int c = 0; c < 8; c++) {
      Piece p = state[r][c];
      if (p != null && p.type == 'P') p.justDoubleStepped = false;
    }
  }
  if (moving.type == 'P' && abs(m.toRow - m.fromRow) == 2) {
    moving.justDoubleStepped = true;
  }
}

void resetEnPassantFlags() {
  for (int r = 0; r < 8; r++) {
    for (int c = 0; c < 8; c++) {
      Piece p = board[r][c];
      if (p != null && p.type == 'P') p.justDoubleStepped = false;
    }
  }
}

boolean inBounds(int r, int c) {
  return r >= 0 && r < 8 && c >= 0 && c < 8;
}

String getPieceSymbol(Piece p) {
  if (p.white) {
    if (p.type == 'K') return "♔";
    if (p.type == 'Q') return "♕";
    if (p.type == 'R') return "♖";
    if (p.type == 'B') return "♗";
    if (p.type == 'N') return "♘";
    return "♙";
  }

  if (p.type == 'K') return "♚";
  if (p.type == 'Q') return "♛";
  if (p.type == 'R') return "♜";
  if (p.type == 'B') return "♝";
  if (p.type == 'N') return "♞";
  return "♟";
}

class Piece {
  char type;
  boolean white;
  boolean hasMoved = false;
  boolean justDoubleStepped = false;

  Piece(char type, boolean white) {
    this.type = type;
    this.white = white;
  }

  Piece clonePiece() {
    Piece p = new Piece(type, white);
    p.hasMoved = hasMoved;
    p.justDoubleStepped = justDoubleStepped;
    return p;
  }
}

class Move {
  int fromRow, fromCol, toRow, toCol;
  boolean enPassant = false;
  boolean castling = false;

  Move(int fromRow, int fromCol, int toRow, int toCol) {
    this.fromRow = fromRow;
    this.fromCol = fromCol;
    this.toRow = toRow;
    this.toCol = toCol;
  }
}
