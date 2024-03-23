; Game.s : ゲーム
;


; モジュール宣言
;
    .module Game

; 参照ファイル
;
    .include    "bios.inc"
    .include    "vdp.inc"
    .include    "System.inc"
    .include    "App.inc"
    .include	"Game.inc"
    .include    "Maze.inc"
    .include    "Player.inc"
    .include    "Enemy.inc"
    .include    "Item.inc"

; 外部変数宣言
;

; マクロの定義
;


; CODE 領域
;
    .area   _CODE

; ゲームを初期化する
;
_GameInitialize::
    
    ; レジスタの保存
    
    ; スプライトのクリア
    call    _SystemClearSprite

    ; サウンドの停止
    call    _SystemStopSound

    ; ゲームの初期化
    ld      hl, #gameDefault
    ld      de, #_game
    ld      bc, #GAME_LENGTH
    ldir
    
    ; 迷路の初期化
    call    _MazeInitialize

    ; プレイヤの初期化
    call    _PlayerInitialize

    ; エネミーの初期化
    call    _EnemyInitialize

    ; アイテムの初期化
    call    _ItemInitialize
    
    ; パターンネームのクリア
;   ld      hl, #(_appPatternName + 0x0000)
;   ld      de, #(_appPatternName + 0x0001)
;   ld      bc, #0x02ff
;   ld      (hl), #0xd0
;   ldir

    ; 枠の描画
    call    GamePrintFrame

    ; パターンネームの転送
    ld      hl, #_appPatternName
    ld      de, #APP_PATTERN_NAME_TABLE
    ld      bc, #0x0300
    call    LDIRVM

    ; 描画の開始
    ld      hl, #(_videoRegister + VDP_R1)
    set     #VDP_R1_BL, (hl)
    
    ; ビデオレジスタの転送
    ld      hl, #_request
    set     #REQUEST_VIDEO_REGISTER, (hl)

    ; 状態の設定
    ld      a, #APP_STATE_GAME_UPDATE
    ld      (_app + APP_STATE), a
    
    ; レジスタの復帰
    
    ; 終了
    ret

; ゲームを更新する
;
_GameUpdate::
    
    ; レジスタの保存
    
    ; スプライトのクリア
    call    _SystemClearSprite
    
    ; 状態別の処理
    ld      hl, #10$
    push    hl
    ld      a, (_game + GAME_STATE)
    and     #0xf0
    rrca
    rrca
    rrca
    ld      e, a
    ld      d, #0x00
    ld      hl, #gameProc
    add     hl, de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    ex      de, hl
    jp      (hl)
;   pop     hl
10$:

    ; パターンネームの転送
    call    _AppTransferPatternName

    ; レジスタの復帰
    
    ; 終了
    ret

; 何もしない
;
GameNull:

    ; レジスタの保存

    ; レジスタの復帰

    ; 終了
    ret
    
; ゲームを開始する
;
GameStart:

    ; レジスタの保存

    ; 初期化処理
    ld      a, (_game + GAME_STATE)
    and     #0x0f
    jr      nz, 09$

    ; 部屋の取得
    xor     a
    call    _MazeGetOrderRoom
    ld      (_game + GAME_ROOM), a

    ; エネミーの配置
    call    _EnemyEntry

    ; メッセージの表示（RETURN FROM mayQ）
    ld      hl, #gamePatternNameStart
    ld      de, #(_appPatternName + 0x00c4)
    ld      bc, #0x0010
    ldir

    ; フレームの初期化
    ld      a, #0x60
    ld      (_game + GAME_FRAME), a

    ; 初期化の完了
    ld      hl, #_game + GAME_STATE
    inc     (hl)
09$:

    ; ステータスの描画
    call    GamePrintStatus

    ; プレイヤの更新
;   call    _PlayerUpdate

    ; エネミーの更新
    call    _EnemyUpdate

    ; プレイヤの描画
    call    _PlayerRender

    ; エネミーの描画
    call    _EnemyRender

    ; メッセージの表示待ち
    ld      a, (_game + GAME_STATE)
    cp      #(GAME_STATE_START + 0x01)
    jr      nz, 19$

    ; フレームの更新
    ld      hl, #(_game + GAME_FRAME)
    dec     (hl)
    jr      nz, 19$

    ; 状態の更新
    ld      hl, #_game + GAME_STATE
    inc     (hl)
19$:

    ; 部屋を現す
    ld      a, (_game + GAME_STATE)
    cp      #(GAME_STATE_START + 0x02)
    jr      nz, 29$

    ; 部屋の描画
    ld      a, (_game + GAME_FRAME)
    ld      d, a
    and     #0x07
    jr      nz, 23$
    call    _MazePrintRoom
    srl     d
    srl     d
    srl     d
    ld      hl, #_appPatternName
    ld      bc, #0x0000
20$:
    ld      a, (hl)
    cp      #0x53
    jr      nz, 21$
    ld      a, d
    or      a
    jr      z, 22$
    ld      a, #(0x50 - 0x01)
    add     a, d
    jr      22$
21$:
    cp      #0x83
    jr      nz, 22$
    ld      a, d
    or      a
    jr      z, 22$
    ld      a, #(0x80 - 0x01)
    add     a, d
;   jr      22$
22$:
    ld      (hl), a
    inc     hl
    inc     bc
    ld      a, b
    cp      #0x03
    jr      c, 20$
23$:

    ; フレームの更新
    ld      hl, #(_game + GAME_FRAME)
    inc     (hl)
    ld      a, (hl)
    cp      #(0x05 * 0x08)
    jr      c, 29$

    ; 状態の更新
    ld      a, #GAME_STATE_PLAY
    ld      (_game + GAME_STATE), a
29$:

    ; レジスタの復帰

    ; 終了
    ret
    
; ゲームをプレイする
;
GamePlay:

    ; レジスタの保存

    ; 初期化処理
    ld      a, (_game + GAME_STATE)
    and     #0x0f
    jr      nz, 09$

    ; エネミーの配置
    call    _EnemyEntry

    ; アイテムの配置
    call    _ItemEntry

    ; 部屋の描画
    call    _MazePrintRoom

    ; BGM の再生
    ld      a, (_game + GAME_ROOM)
    call    _MazeGetSound
    call    _GamePlayBgm

    ; 初期化の完了
    ld      hl, #(_game + GAME_STATE)
    inc     (hl)
09$:

    ; ダメージの監視
    ld      hl, #(_game + GAME_FLAG)
    call    _PlayerIsDamage
    jr      c, 10$
    call    _EnemyIsDamage
    jr      c, 10$
    res     #GAME_FLAG_WAIT_BIT, (hl)
    jr      11$
10$:
    set     #GAME_FLAG_WAIT_BIT, (hl)
;   jr      11$
11$:

    ; プレイヤの更新
    call    _PlayerUpdate

    ; エネミーの更新
    call    _EnemyUpdate

    ; アイテムの更新
    call    _ItemUpdate

    ; プレイヤの描画
    call    _PlayerRender

    ; エネミーの描画
    call    _EnemyRender

    ; アイテムの描画
    call    _ItemRender

    ; ステータスの描画
    call    GamePrintStatus

    ; フレームの更新
    ld      hl, #(_game + GAME_FRAME)
    inc     (hl)

    ; リクエストの監視
    ld      hl, #(_game + GAME_REQUEST)

    ; リクエスト／部屋の移動
    ld      de, #(_game + GAME_ROOM)
900$:
    bit     #GAME_REQUEST_ROOM_UP_BIT, (hl)
    jr      z, 901$
    ld      a, (de)
    sub     #MAZE_SIZE_X
    and     #MAZE_SIZE_Y_MASK
    ld      c, a
    ld      a, (de)
    and     #MAZE_SIZE_X_MASK
    add     a, c
    ld      (de), a
    ld      de, #((MAZE_EXIT_DOWN_Y << 8) | MAZE_EXIT_DOWN_X)
    jr      908$
901$:
    bit     #GAME_REQUEST_ROOM_DOWN_BIT, (hl)
    jr      z, 902$
    ld      a, (de)
    add     a, #MAZE_SIZE_X
    and     #MAZE_SIZE_Y_MASK
    ld      c, a
    ld      a, (de)
    and     #MAZE_SIZE_X_MASK
    add     a, c
    ld      (de), a
    ld      de, #((MAZE_EXIT_UP_Y << 8) | MAZE_EXIT_UP_X)
    jr      908$
902$:
    bit     #GAME_REQUEST_ROOM_LEFT_BIT, (hl)
    jr      z, 903$
    ld      a, (de)
    dec     a
    and     #MAZE_SIZE_X_MASK
    ld      c, a
    ld      a, (de)
    and     #MAZE_SIZE_Y_MASK
    add     a, c
    ld      (de), a
    ld      de, #((MAZE_EXIT_RIGHT_Y << 8) | MAZE_EXIT_RIGHT_X)
    jr      908$
903$:
    bit     #GAME_REQUEST_ROOM_RIGHT_BIT, (hl)
    jr      z, 909$
    ld      a, (de)
    inc     a
    and     #MAZE_SIZE_X_MASK
    ld      c, a
    ld      a, (de)
    and     #MAZE_SIZE_Y_MASK
    add     a, c
    ld      (de), a
    ld      de, #((MAZE_EXIT_LEFT_Y << 8) | MAZE_EXIT_LEFT_X)
;   jr      908$
908$:
    ld      (_player + PLAYER_POSITION_X), de
    ld      de, #(_game + GAME_STATE)
    ld      a, (de)
    and     #0xf0
    ld      (de), a
909$:
    ld      a, (hl)
    and     #~(GAME_REQUEST_ROOM_UP | GAME_REQUEST_ROOM_DOWN | GAME_REQUEST_ROOM_LEFT | GAME_REQUEST_ROOM_RIGHT)
    ld      (hl), a

    ; リクエスト／描画
910$:
    bit     #GAME_REQUEST_PRINT_COMPASS_BIT, (hl)
    jr      z, 919$
    call    GamePrintCompass
;   jr      919$
919$:
    res     #GAME_REQUEST_PRINT_COMPASS_BIT, (hl)

    ; リクエスト／ゲームオーバー
920$:
    bit     #GAME_REQUEST_OVER_BIT, (hl)
    jr      z, 929$
    ld      a, #GAME_STATE_OVER
    ld      (_game + GAME_STATE), a
929$:
;   res     #GAME_REQUEST_OVER_BIT, (hl)

    ; リクエスト／ゲートをくぐる
930$:
    bit     #GAME_REQUEST_GATE_ENTER_BIT, (hl)
    jr      z, 939$
    ld      a, #GAME_STATE_CLEAR
    ld      (_game + GAME_STATE), a
939$:
;   res     #GAME_REQUEST_GATE_ENTER_BIT, (hl)

    ; プレイの完了

    ; レジスタの復帰

    ; 終了
    ret
    
; ゲームオーバーになる
;
GameOver:

    ; レジスタの保存

    ; 初期化処理
    ld      a, (_game + GAME_STATE)
    and     #0x0f
    jr      nz, 09$

    ; BGM の再生
    ld      a, #GAME_SOUND_BGM_OVER
    call    _GamePlayBgm

    ; 部屋を消す
    ld      hl, #_appPatternName
    ld      bc, #0x0300
00$:
    ld      a, (hl)
    cp      #0x50
    jr      c, 02$
    cp      #(0x53 + 0x01)
    jr      c, 01$
    cp      #0x80
    jr      c, 02$
    cp      #(0x87 + 0x01)
    jr      nc, 02$
01$:
    xor     a
    ld      (hl), a
02$:
    inc     hl
    dec     bc
    ld      a, b
    or      c
    jr      nz, 00$

    ; メッセージの表示（GAME  OVER）
    ld      hl, #gamePatternNameOver
    ld      de, #(_appPatternName + 0x0187)
    ld      bc, #0x000a
    ldir

    ; 初期化の完了
    ld      hl, #(_game + GAME_STATE)
    inc     (hl)
09$:

    ; ステータスの描画
    call    GamePrintStatus

    ; キー入力待ち
    ld      a, (_input + INPUT_BUTTON_SPACE)
    dec     a
    jr      nz, 10$
    ld      a, #GAME_STATE_END
    ld      (_game + GAME_STATE), a
;   jr      10$
10$: 

    ; レジスタの復帰

    ; 終了
    ret

; ゲームをクリアする
;
GameClear:

    ; レジスタの保存

    ; 初期化処理
    ld      a, (_game + GAME_STATE)
    and     #0x0f
    jr      nz, 09$

    ; プレイヤをゲートに向かわせる
    ld      a, #PLAYER_STATE_GATE
    ld      (_player + PLAYER_STATE), a

    ; フレームの初期化
    ld      a, #(0x05 * 0x20)
    ld      (_game + GAME_FRAME), a

    ; サウンドの停止
    call    _SystemStopSound

    ; 初期化の完了
    ld      hl, #(_game + GAME_STATE)
    inc     (hl)
09$:

    ; プレイヤの更新
    call    _PlayerUpdate

    ; エネミーの更新
    call    _EnemyUpdate

    ; アイテムの更新
    call    _ItemUpdate

    ; プレイヤの描画
    call    _PlayerRender

    ; エネミーの描画
    call    _EnemyRender

    ; アイテムの描画
    call    _ItemRender

    ; ステータスの描画
    call    GamePrintStatus

    ; 部屋を消す
10$:
    ld      a, (_game + GAME_STATE)
    cp      #(GAME_STATE_CLEAR + 0x01)
    jr      nz, 20$

    ; フレームの更新
    ld      hl, #(_game + GAME_FRAME)
    dec     (hl)
    ld      a, (hl)
    ld      d, a
    inc     a
    and     #0x1f
    jr      nz, 14$

    ; フェード
    srl     d
    srl     d
    srl     d
    srl     d
    srl     d
    call    _MazePrintRoom
    ld      hl, #_appPatternName
    ld      bc, #0x0000
11$:
    ld      a, (hl)
    cp      #0x53
    jr      nz, 12$
    ld      a, d
    or      a
    jr      z, 13$
    add     a, #(0x50 - 0x01)
    jr      13$
12$:
    cp      #0x83
    jr      nz, 13$
    ld      a, d
    or      a
    jr      z, 13$
    add     a, #(0x80 - 0x01)
;   jr      13$
13$:
    ld      (hl), a
    inc     hl
    inc     bc
    ld      a, b
    cp      #0x03
    jr      c, 11$
14$:
    ld      a, (_game + GAME_FRAME)
    or      a
    jr      nz, 19$

    ; BGM の再生
    ld      a, #GAME_SOUND_BGM_CLEAR
    call    _GamePlayBgm

    ; 状態の更新
    ld      hl, #(_game + GAME_STATE)
    inc     (hl)
19$:
    jr      90$

    ; メッセージの表示（CONGRATULATIONS!）
20$:
    ld      a, (_game + GAME_STATE)
    cp      #(GAME_STATE_CLEAR + 0x02)
    jr      nz, 30$
    ld      hl, #gamePatternNameClear0
    ld      de, #(_appPatternName + 0x00a4)
    call    80$
    jr      90$

    ; メッセージの表示（YOU'VE RETURNED FROM）
30$:
    ld      a, (_game + GAME_STATE)
    cp      #(GAME_STATE_CLEAR + 0x03)
    jr      nz, 40$
    ld      hl, #gamePatternNameClear1
    ld      de, #(_appPatternName + 0x0222)
    call    80$
    jr      90$

    ; メッセージの表示（mayQ）
40$:
    ld      a, (_game + GAME_STATE)
    cp      #(GAME_STATE_CLEAR + 0x04)
    jr      nz, 50$
    ld      hl, #gamePatternNameClear2
    ld      de, #(_appPatternName + 0x026a)
    call    80$
    jr      90$

    ; キー入力待ち
50$:
    ld      a, (_input + INPUT_BUTTON_SPACE)
    dec     a
    jr      nz, 59$
    ld      a, #GAME_STATE_END
    ld      (_game + GAME_STATE), a
;   jr      59$
59$:
    jr      90$

    ; メッセージの表示
80$:
    ld      a, (_game + GAME_FRAME)
    inc     a
    ld      (_game + GAME_FRAME), a
    srl     a
    srl     a
    inc     a
    ld      b, a
81$:
    ld      a, (hl)
    cp      #0xff
    jr      z, 82$
    ld      (de), a
    inc     hl
    inc     de
    djnz    81$
    jr      89$
82$:
    xor     a
    ld      (_game + GAME_FRAME), a
    ld      hl, #(_game + GAME_STATE)
    inc     (hl)
;   jr      89$
89$:
    ret

    ; クリアの完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

; ゲームを終了する
;
GameEnd:

    ; レジスタの保存

    ; 初期化処理
    ld      a, (_game + GAME_STATE)
    and     #0x0f
    jr      nz, 09$

    ; 画面のクリア
    ld      hl, #(_appPatternName + 0x0000)
    ld      de, #(_appPatternName + 0x0000)
    ld      bc, #0x0030
    xor     a
    ld      (hl), a
    ldir

    ; 初期化の完了
    ld      hl, #(_game + GAME_STATE)
    inc     (hl)
09$:

    ; 状態の更新
    ld      a, #APP_STATE_TITLE_INITIALIZE
    ld      (_app + APP_STATE), a

    ; レジスタの復帰

    ; 終了
    ret

; ゲームの枠を描画する
;
GamePrintFrame:

    ; レジスタの保存
    push    hl
    push    bc
    push    de

    ; 枠の描画
    ld      hl, #gamePatternNameFrame
    ld      de, #_appPatternName
10$:
    ld      a, (hl)
    cp      #0xff
    jr      z, 19$
    inc     hl
    cp      (hl)
    jr      z, 11$
    ld      (de), a
    inc     de
    jr      10$
11$:
    inc     hl
    ld      b, (hl)
12$:
    ld      (de), a
    inc     de
    djnz    12$
    inc     hl
    jr      10$
19$:

    ; レジスタの復帰
    pop     de
    pop     bc
    pop     hl

    ; 終了
    ret

; 磁石を描画する
;
GamePrintCompass:

    ; レジスタの保存
    push    hl
    push    bc
    push    de

    ; 磁石の描画
    ld      hl, #(_appPatternName + 0x0238)
    ld      a, #0x54
    ld      b, #0x03
10$:
    ld      (hl), a
    inc     hl
    inc     a
    djnz    10$
    ld      hl, #(_appPatternName + 0x0259)
    ld      de, #(0x0020 - 0x0006)
    ld      c, #0x04
    ld      a, #0x88
11$:
    ld      b, #0x06
12$:
    ld      (hl), a
    inc     hl
    inc     a
    djnz    12$
    add     hl, de
    dec     c
    jr      nz, 11$

    ; レジスタの復帰
    pop     de
    pop     bc
    pop     hl

    ; 終了
    ret

; ステータスを描画する
;
GamePrintStatus:

    ; レジスタの保存
    push    hl
    push    bc
    push    de

    ; 体力の描画
    ld      hl, #(_appPatternName + 0x0078)
    ld      a, (_player + PLAYER_LIFE)
    ld      d, a
    ld      bc, #(((PLAYER_LIFE_MAX / 0x08) << 8) | 0x0008)
10$:
    ld      a, d
    sub     c
    jr      c, 11$
    ld      d, a
    ld      a, c
    jr      12$
11$:
    ld      a, d
    ld      d, #0x00
12$:
    add     a, #0x77
    ld      (hl), a
    inc     hl
    djnz    10$
19$:

    ; 状態異常の描画
    ld      hl, #(_appPatternName + 0x00d8)
    ld      de, #(_appPatternName + 0x00d9)
    ld      bc, #(PLAYER_CONDITION_LENGTH - 0x0002)
    xor     a
    ld      (hl), a
    ldir
    ld      hl, #(_player + PLAYER_CONDITION_POISON_L)
    ld      de, #(_appPatternName + 0x00d8)
    ld      bc, #(((PLAYER_CONDITION_LENGTH - PLAYER_CONDITION_POISON) << 8) | 0x0068)
20$:
    ld      a, (hl)
    inc     hl
    or      (hl)
    jr      z, 21$
    ld      a, c
    ld      (de), a
    inc     de
21$:
    inc     hl
    inc     c
    djnz    20$

    ; 攻撃力の描画
    ld      c, #0x57
    ld      hl, (_player + PLAYER_CONDITION_UNPOWER_L)
    ld      a, h
    or      l
    jr      z, 30$
    ld      c, #0x6a
30$:
    ld      hl, #(_appPatternName + 0x0158)
    ld      a, (_player + PLAYER_ITEM_SWORD)
    add     a, #PLAYER_POWER_POINT_NORMAL
    ld      b, a
31$:
    ld      (hl), c
    inc     hl
    djnz    31$

    ; 防御力の描画
    ld      c, #0x58
    ld      hl, (_player + PLAYER_CONDITION_UNGUARD_L)
    ld      a, h
    or      l
    jr      z, 40$
    ld      c, #0x6b
40$:
    ld      hl, #(_appPatternName + 0x0178)
    ld      a, (_player + PLAYER_ITEM_SHIELD)
    add     a, #PLAYER_GUARD_POINT_NORMAL
    ld      b, a
41$:
    ld      (hl), c
    inc     hl
    djnz    41$

    ; アイテムの描画
    ld      hl, #(_appPatternName + 0x01d8)
    ld      de, #(_player + PLAYER_ITEM_BOOTS)
    ld      bc, #((ITEM_BOOTS << 8) | 0x0000)
50$:
    ld      a, (de)
    or      a
    jr      z, 51$
    ld      a, b
    add     a, #0x56
    ld      (hl), a
    inc     hl
    inc     c
    ld      a, c
    cp      #0x07
    jr      c, 51$
    ld      c, #0x00
    push    bc
    ld      bc, #(0x0020 - 0x0007)
    add     hl, bc
    pop     bc
51$:
    inc     de
    inc     b
    ld      a, b
    cp      #ITEM_LENGTH
    jr      c, 50$

    ; 磁石の描画
    ld      a, (_player + PLAYER_ITEM_COMPASS)
    or      a
    jr      z, 60$
    ld      a, (_game + GAME_FRAME)
    and     #0x10
    jr      z, 60$
    ld      hl, #(_sprite + GAME_SPRITE_COMPASS)
    ld      a, (_game + GAME_ROOM)
    ld      c, a
    and     #MAZE_SIZE_Y_MASK
    rrca
    rrca
    ld      b, a
    rrca
    add     a, b
    add     a, #(0x94 - 0x01)
    ld      (hl), a
    inc     hl
    ld      a, c
    and     #MAZE_SIZE_X_MASK
    ld      c, a
    add     a, a
    add     a, a
    add     a, c
    add     a, #0xc9
    ld      (hl), a
    inc     hl
    ld      a, #0x02
    ld      (hl), a
    inc     hl
    ld      a, #APP_COLOR_ORANGE
    ld      (hl), a
;   inc     hl
60$:

    ; レジスタの復帰
    pop     de
    pop     bc
    pop     hl

    ; 終了
    ret

; BGM を再生する
;
_GamePlayBgm::

    ; レジスタの保存
    push    hl
    push    de

    ; a = 再生する音

    ; サウンドの再生
    ld      hl, #(_game + GAME_SOUND)
    cp      (hl)
    jr      z, 19$
    ld      (hl), a
    add     a, a
    add     a, a
    add     a, a
    ld      e, a
    ld      d, #0x00
    ld      hl, #gameSoundBgm
    add     hl, de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    inc     hl
    ld      (_soundRequest + 0x0000), de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    inc     hl
    ld      (_soundRequest + 0x0002), de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
;   inc     hl
    ld      (_soundRequest + 0x0004), de
19$:

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

; SE を再生する
;
_GamePlaySe::

    ; レジスタの保存
    push    hl
    push    de

    ; a = 再生する音
    add     a, a
    ld      e, a
    ld      d, #0x00
    ld      hl, #gameSoundSe
    add     hl, de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    ld      (_soundRequest + 0x0006), de

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

; 定数の定義
;

; 状態別の処理
;
gameProc:
    
    .dw     GameNull
    .dw     GameStart
    .dw     GamePlay
    .dw     GameOver
    .dw     GameClear
    .dw     GameEnd

; ゲームの初期値
;
gameDefault:

    .db     GAME_STATE_START
    .db     GAME_FLAG_NULL
    .db     GAME_REQUEST_NULL
    .db     GAME_ROOM_NULL
    .db     GAME_SOUND_NULL
    .db     GAME_FRAME_NULL

; パターンネーム
;

; 枠
gamePatternNameFrame:

    .db     0x44, 0x49, 0x49, 0x16, 0x40, 0x49, 0x49, 0x07, 0x45
    .db     0x48, 0x00, 0x00, 0x16, 0x48, 0x00, 0x00, 0x07
    .db     0x48, 0x48, 0x02
    .db     0x00, 0x00, 0x16, 0x48, 0xa0, 0xa1, 0xa2, 0x00, 0x00, 0x04
    .db     0x48, 0x48, 0x02
    .db     0x00, 0x00, 0x16, 0x48, 0x00, 0x00, 0x07
    .db     0x48, 0x48, 0x02
    .db     0x00, 0x00, 0x16, 0x48, 0x00, 0x00, 0x07
    .db     0x48, 0x48, 0x02
    .db     0x00, 0x00, 0x16, 0x48, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa8, 0x00
    .db     0x48, 0x48, 0x02
    .db     0x00, 0x00, 0x16, 0x48, 0x00, 0x00, 0x07
    .db     0x48, 0x48, 0x02
    .db     0x00, 0x00, 0x16, 0x4c, 0x4a, 0x4a, 0x07, 0x4e
    .db     0x48, 0x00, 0x00, 0x16, 0x4d, 0x4b, 0x4b, 0x07, 0x4f
    .db     0x48, 0x00, 0x00, 0x16, 0x48, 0xa9, 0xaa, 0xab, 0xac, 0x00, 0x00, 0x03
    .db     0x48, 0x48, 0x02
    .db     0x00, 0x00, 0x16, 0x48, 0x00, 0x00, 0x07
    .db     0x48, 0x48, 0x02
    .db     0x00, 0x00, 0x16, 0x48, 0x00, 0x00, 0x07
    .db     0x48, 0x48, 0x02
    .db     0x00, 0x00, 0x16, 0x48, 0x00, 0x00, 0x07
    .db     0x48, 0x48, 0x02
    .db     0x00, 0x00, 0x16, 0x48, 0xad, 0xae, 0xaf, 0x00, 0x00, 0x04
    .db     0x48, 0x48, 0x02
    .db     0x00, 0x00, 0x16, 0x48, 0x00, 0x00, 0x07
    .db     0x48, 0x48, 0x02
    .db     0x00, 0x00, 0x16, 0x48, 0x00, 0x00, 0x07
    .db     0x48, 0x48, 0x02
    .db     0x00, 0x00, 0x16, 0x48, 0x00, 0x00, 0x07
    .db     0x48, 0x48, 0x02
    .db     0x00, 0x00, 0x16, 0x48, 0x00, 0x00, 0x07
    .db     0x48, 0x48, 0x02
    .db     0x00, 0x00, 0x16, 0x48, 0x00, 0x00, 0x07
    .db     0x48, 0x48, 0x02
    .db     0x00, 0x00, 0x16, 0x48, 0x00, 0x00, 0x07
    .db     0x48, 0x48, 0x02
    .db     0x00, 0x00, 0x16, 0x48, 0x00, 0x00, 0x07
    .db     0x48, 0x48, 0x02
    .db     0x00, 0x00, 0x16, 0x48, 0x00, 0x00, 0x07
    .db     0x48, 0x48, 0x02
    .db     0x00, 0x00, 0x16, 0x48, 0x00, 0x00, 0x07, 0x48
    .db     0x46, 0x49, 0x49, 0x16, 0x41, 0x49, 0x49, 0x07, 0x47
    .db     0xff

; スタート
gamePatternNameStart:

    ; RETURN FROM mayQ
    .db     0x32, 0x25, 0x34, 0x35, 0x32, 0x2e, 0x00, 0x26, 0x32, 0x2f, 0x2d, 0x00, 0x70, 0x71, 0x72, 0x73

; ゲームオーバー
gamePatternNameOver:

    ; GAME  OVER
    .db     0x27, 0x21, 0x2d, 0x25, 0x00, 0x00, 0x2f, 0x36, 0x25, 0x32

; クリア
gamePatternNameClear0:

    ; CONGRATULATIONS!
    .db     0x23, 0x2f, 0x2e, 0x27, 0x32, 0x21, 0x34, 0x35, 0x2c, 0x21, 0x34, 0x29, 0x2f, 0x2e, 0x33, 0x01, 0xff

gamePatternNameClear1:

    ; YOU'VE RETURNED FROM
    .db     0x39, 0x2f, 0x35, 0x07, 0x36, 0x25, 0x00, 0x32, 0x25, 0x34, 0x35, 0x32, 0x2e, 0x25, 0x24, 0x00, 0x26, 0x32, 0x2f, 0x2d, 0xff

gamePatternNameClear2:

    ; mayQ
    .db     0x70, 0x71, 0x72, 0x73, 0xff

; サウンド
;
gameSoundBgm:

    .dw     gameSoundNull
    .dw     gameSoundNull
    .dw     gameSoundNull
    .dw     gameSoundNull
    .dw     gameSoundBgmZako0
    .dw     gameSoundBgmZako1
    .dw     gameSoundBgmZako2
    .dw     gameSoundNull
    .dw     gameSoundBgmBoss0
    .dw     gameSoundBgmBoss1
    .dw     gameSoundBgmBoss2
    .dw     gameSoundNull
    .dw     gameSoundBgmOver0
    .dw     gameSoundBgmOver1
    .dw     gameSoundBgmOver2
    .dw     gameSoundNull
    .dw     gameSoundBgmClear0
    .dw     gameSoundBgmClear1
    .dw     gameSoundBgmClear2
    .dw     gameSoundNull
    
gameSoundSe:

    .dw     gameSoundNull
    .dw     gameSoundSeHit
    .dw     gameSoundSeMiss
    .dw     gameSoundSeDamageNormal
    .dw     gameSoundSeDamagePoison
    .dw     gameSoundSeCast
    .dw     gameSoundSeItem

gameSoundNull:

    .ascii  "T1L0R"
    .db     0x00

gameSoundBgmZako0:

    .ascii  "T4V15-3L5"
    .ascii  "O2GGGG3A3O2GGGG3A3"
    .ascii  "O2GGGG3A3O2GGGG3A3O2GGGG3A3O2GGGG3A3"
    .ascii  "O2GGGG3A3O2GGGG3A3O2GGGG3A3O2GGGG3A3"
    .db     0xff

gameSoundBgmZako1:

    .ascii  "T4V15-3L9"
    .ascii  "RR"
    .ascii  "O5DEFE"
    .ascii  "O5DEFE"
    .db     0xff

gameSoundBgmZako2:

    .ascii  "T4V15-3L9"
    .ascii  "RR"
    .ascii  "O4GAB-A"
    .ascii  "O4GAB-A"
    .db     0xff

gameSoundBgmBoss0:

    .ascii  "T3V15-3L6"
    .ascii  "O5CO4GO5CO4GO5CO4GEC"
    .db     0xff

gameSoundBgmBoss1:

    .ascii  "T3V15-3L1"
    .ascii  "O3EEEEEEREREEEREEEEEREREEE"
    .ascii  "O3EEEEEEREREEEREEEEEREREEE"
    .ascii  "O3EEEEEEREREEEREEEEEREREEE"
    .ascii  "O3EEEEEEREREEEREEEEEREREEE"
    .db     0xff

gameSoundBgmBoss2:

    .ascii  "T3V15-3L3"
    .ascii  "O2AAO3E5R5O2AAO3E5R5O2AAO3E5R5O2AAO3E5R5"
    .ascii  "O2AAO3E5R5O2AAO3E5R5O2AAO3E5R5O2AAO3E5R5"
    .db     0xff

gameSoundBgmOver0:

    .ascii  "T4V15-5L6"
    .ascii  "O4ADDR"
    .db     0x00

gameSoundBgmOver1:

    .ascii  "T4V15-5L6"
    .ascii  "O4DO3BBR"
    .db     0x00

gameSoundBgmOver2:

    .ascii  "T4V15-5L6"
    .ascii  "O3GDO2AR"
    .db     0x00

gameSoundBgmClear0:

    .ascii  "T3V15-3L5"
    .ascii  "O4A7B-7B-GEC"
    .ascii  "O5CO4B-AB-AG1A1G1A1F7"
    .db     0x00

gameSoundBgmClear1:

    .ascii  "T3V15-3L5"
    .ascii  "O5E-7F7B-GER"
    .ascii  "O4FFO5CO4GFEF7"
    .db     0x00

gameSoundBgmClear2:

    .ascii  "T3V15-3L5"
    .ascii  "O5C7D7DO4B-GR"
    .ascii  "O4CDFDCCC7"
    .db     0x00

gameSoundSeHit:

    .ascii  "T1V15O6B3"
    .db     0x00

gameSoundSeMiss:

    .ascii  "T1V15-1O7B5"
    .db     0x00

gameSoundSeDamageNormal:

    .ascii  "T1V15O5B3"
    .db     0x00

gameSoundSeDamagePoison:

    .ascii  "T1V15O1B1"
    .db     0x00

gameSoundSeCast:

    .ascii  "T1V15L0O4BABABABA"
    .db     0x00

gameSoundSeItem:

    .ascii  "T1V15L1O5EE-G-FA"
    .db     0x00


; DATA 領域
;
    .area   _DATA

; 変数の定義
;

; ゲーム
;
_game::
    
    .ds     GAME_LENGTH
