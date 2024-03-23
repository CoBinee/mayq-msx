; Title.s : タイトル
;


; モジュール宣言
;
    .module Title

; 参照ファイル
;
    .include    "bios.inc"
    .include    "vdp.inc"
    .include    "System.inc"
    .include    "App.inc"
    .include	"Title.inc"

; 外部変数宣言
;

; マクロの定義
;


; CODE 領域
;
    .area   _CODE

; タイトルを初期化する
;
_TitleInitialize::
    
    ; レジスタの保存
    
    ; スプライトのクリア
    call    _SystemClearSprite

    ; パターンネームのクリア
    ld      hl, #(_appPatternName + 0x0000)
    ld      de, #(_appPatternName + 0x0001)
    ld      bc, #0x02ff
    ld      (hl), #0x00
    ldir

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

    ; サウンドの停止
    call    _SystemStopSound
    
    ; タイトルの設定
    ld      hl, #titleDefault
    ld      de, #_title
    ld      bc, #TITLE_LENGTH
    ldir

    ; 状態の更新
    ld      a, #APP_STATE_TITLE_UPDATE
    ld      (_app + APP_STATE), a
    
    ; レジスタの復帰
    
    ; 終了
    ret

; タイトルを更新する
;
_TitleUpdate::
    
    ; レジスタの保存

    ; 初期化処理
    ld      a, (_title + TITLE_STATE)
    cp      #(TITLE_STATE_NULL + 0x00)
    jr      nz, 09$

    ; 導入の描画
    ld      hl, #titlePatternNameIntro
    ld      de, #(_appPatternName + 0x165)
    ld      bc, #0x15
    ldir

    ; フレームの設定
    ld      a, #0x5a
    ld      (_title + TITLE_FRAME), a

    ; 初期化の完了
    ld      hl, #(_title + TITLE_STATE)
    inc     (hl)
09$:

    ; スプライトのクリア
    call    _SystemClearSprite

    ; 乱数を回す
    call    _SystemGetRandom
    
    ; 導入
    ld      a, (_title + TITLE_STATE)
    cp      #(TITLE_STATE_NULL + 0x01)
    jr      nz, 19$

    ; フレームの更新
    ld      hl, #(_title + TITLE_FRAME)
    dec     (hl)
    jr      nz, 19$

    ; フレームの設定
    xor     a
    ld      (_title + TITLE_FRAME), a

    ; 状態の更新
    ld      hl, #(_title + TITLE_STATE)
    inc     (hl)
19$:

    ; 背景のフェード
    ld      a, (_title + TITLE_STATE)
    cp      #(TITLE_STATE_NULL + 0x02)
    jr      nz, 29$

    ; フェード
    ld      a, (_title + TITLE_FRAME)
    ld      c, a
    and     #0x0f
    jr      nz, 20$
    ld      a, c
    rrca
    rrca
    rrca
    rrca
    call    800$
    ld      hl, #titleSoundFade
    ld      (_soundRequest + 0x0004), hl
20$:

    ; フレームの更新
    ld      hl, #(_title + TITLE_FRAME)
    inc     (hl)
    ld      a, (hl)
    cp      #(0x05 * 0x10)
    jr      c, 29$

    ; BGM の再生
    ld      hl, #titleSoundBgm0
    ld      (_soundRequest + 0x0000), hl
    ld      hl, #titleSoundBgm1
    ld      (_soundRequest + 0x0002), hl
    ld      hl, #titleSoundBgm2
    ld      (_soundRequest + 0x0004), hl

    ; 状態の更新
    ld      hl, #(_title + TITLE_STATE)
    inc     (hl)
29$:

    ; ページの更新
    ld      a, (_title + TITLE_STATE)
    cp      #(TITLE_STATE_NULL + 0x03)
    jr      nz, 39$

    ; 背景の描画
    ld      a, #0x04
    call    800$

    ; ページの描画
    call    810$

    ; カーソルの描画
    call    820$

    ; 状態の更新
    ld      hl, #(_title + TITLE_STATE)
    inc     (hl)
39$:

    ; キー入力待ち
    ld      a, (_title + TITLE_STATE)
    cp      #(TITLE_STATE_NULL + 0x04)
    jr      nz, 49$

    ; フレームの更新
    ld      hl, #(_title + TITLE_FRAME)
    inc     (hl)

    ; スタートの更新
    ld      hl, #(_title + TITLE_START)
    inc     (hl)

    ; HIT SPACE BAR の描画
    call    830$

    ; スプライトの描画
    call    840$

    ; ←キーの監視
    ld      hl, #(_title + TITLE_PAGE)
    ld      a, (_input + INPUT_KEY_LEFT)
    dec     a
    jr      nz, 40$
    dec     (hl)
    ld      a, (hl)
    cp      #TITLE_PAGE_LENGTH
    jr      c, 41$
    ld      a, #(TITLE_PAGE_LENGTH - 1)
    jr      41$

    ; →キーの監視    
40$:
    ld      a, (_input + INPUT_KEY_RIGHT)
    dec     a
    jr      nz, 42$
    inc     (hl)
    ld      a, (hl)
    cp      #TITLE_PAGE_LENGTH
    jr      c, 41$
    xor     a
;   jr      41$

    ;  ページの更新
41$:
    ld      (hl), a
    ld      hl, #(_title + TITLE_STATE)
    dec     (hl)
    ld      hl, #titleSoundClick
    ld      (_soundRequest + 0x0006), hl
    jr      49$

    ; SPACE キーの監視
42$:
    ld      a, (_input + INPUT_BUTTON_SPACE)
    dec     a
    jr      nz, 43$

    ; サウンドの停止
    call    _SystemStopSound

    ; SE の再生
    ld      hl, #titleSoundStart
    ld      (_soundRequest + 0x0000), hl

    ; 状態の更新
    ld      hl, #(_title + TITLE_STATE)
    inc     (hl)
    jr      49$

    ; ESC キーの監視
43$:
;   ld      a, (_input + INPUT_BUTTON_ESC)
;   dec     a
;   jr      nz, 49$

    ; 状態の更新
;   ld      a, #APP_STATE_DEBUG_INITIALIZE
;   ld      (_app + APP_STATE), a
;   jr      49$
49$:

    ; ゲームの開始
    ld      a, (_title + TITLE_STATE)
    cp      #(TITLE_STATE_NULL + 0x05)
    jr      nz, 59$

    ; フレームの更新
    ld      hl, #(_title + TITLE_FRAME)
    inc     (hl)

    ; スタートの更新
    ld      hl, #(_title + TITLE_START)
    ld      a, (hl)
    add     a, #0x08
    ld      (hl), a

    ; HIT SPACE BAR の描画
    call    830$

    ; スプライトの描画
    call    840$

    ; サウンドの監視
    ld      hl, (_soundRequest + 0x0000)
    ld      a, h
    or      l
    jr      nz, 59$
    ld      hl, (_soundPlay + 0x0000)
    ld      a, h
    or      l
    jr      nz, 59$

    ; 状態の更新
    ld      a, #APP_STATE_GAME_INITIALIZE
    ld      (_app + APP_STATE), a
59$:    
    jp      90$

    ; 背景の描画
800$:
    or      a
    jr      z, 801$
    add     a, #(0x80 - 0x01)
801$:
    ld      c, a
    ld      hl, #titlePatternNameBack
    ld      de, #_appPatternName
802$:
    ld      a, (hl)
    cp      #0xff
    jr      z, 809$
    inc     hl
    ld      b, a
    ld      a, c
803$:
    ld      (de), a
    inc     de
    djnz    803$
    ld      a, (hl)
    cp      #0xff
    jr      z, 809$
    inc     hl
    ld      b, a
    ld      a, #0x00
804$:
    ld      (de), a
    inc     de
    djnz    804$
    jr      802$
809$:
    ret

    ; ページの描画
810$:
    ld      a, (_title + TITLE_PAGE)
    add     a, a
    ld      e, a
    ld      d, #0x00
    ld      hl, #titlePatternNamePage
    add     hl, de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    ex      de, hl
    ld      de, #_appPatternName
    ld      bc, #0x0000
811$:
    ld      a, (hl)
    inc     hl
    or      a
    jr      z, 812$
    ld      (de), a
    inc     de
    inc     bc
    jr      813$
812$:
    push    hl
    ld      l, (hl)
    ld      h, a
    push    hl
    add     hl, de
    ex      de, hl
    pop     hl
    add     hl, bc
    ld      c, l
    ld      b, h
    pop     hl
    inc     hl
813$:
    ld      a, b
    cp      #0x03
    jr      c, 811$
    ret

    ; カーソルの描画
820$:
    ld      hl, #titlePatternNameCursor
    ld      de, #(_appPatternName + 0x2bc)
    ld      bc, #0x0003
    ldir
    ret

    ; HIT SPACE BAR の描画
830$:
    ld      a, (_title + TITLE_PAGE)
    or      a
    jr      nz, 839$
    ld      hl, #(_title + TITLE_START)
    ld      a, (hl)
    and     #0x10
    ld      hl, #titlePatternNameHitSpaceBar
    ld      de, #(_appPatternName + 0x0229)
    ld      bc, #0x000d
    jr      nz, 831$
    add     hl, bc
831$:
    ldir
839$:
    ret

    ; スプライトの描画
840$:
    ld      a, (_title + TITLE_PAGE)
    ld      e, a
    ld      d, #0x00
    ld      hl, #titleSpritePageAnimation
    add     hl, de
    ld      c, (hl)
    add     a, a
    ld      e, a
    ld      hl, #titleSpritePage
    add     hl, de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    ex      de, hl
    ld      de, #_sprite
    ld      a, (_title + TITLE_FRAME)
    rrca
    rrca
    rrca
    and     c
    ld      c, a
841$:
    ld      a, (hl)
    cp      #0xff
    jr      z, 842$
    ld      (de), a
    inc     hl
    inc     de
    ld      a, (hl)
    ld      (de), a
    inc     hl
    inc     de
    ld      a, (hl)
    add     a, c
    ld      (de), a
    inc     hl
    inc     de
    ld      a, (hl)
    ld      (de), a
    inc     hl
    inc     de
    jr      841$
842$:
    ret

    ; 更新の完了
90$:

    ; パターンネームの転送
    call    _AppTransferPatternName

    ; レジスタの復帰
    
    ; 終了
    ret

; 定数の定義
;

; タイトルの初期値
;
titleDefault:

    .db     TITLE_STATE_NULL
    .db     TITLE_FRAME_NULL
    .db     TITLE_PAGE_LOGO
    .db     TITLE_START_NULL

; パターンネーム
;

; 導入
titlePatternNameIntro:

    .db     0x39, 0x2f, 0x35, 0x00, 0x26, 0x2f, 0x35, 0x2e, 0x24, 0x00, 0x39, 0x2f, 0x35, 0x32, 0x33, 0x25, 0x2c, 0x26, 0x00, 0x29, 0x2e

; 背景
titlePatternNameBack:

    .db     0x21
    .db           0x02, 0x03, 0x05, 0x0a, 0x01, 0x0a
    .db     0x0c, 0x04, 0x01, 0x04, 0x02, 0x02, 0x02, 0x05
    .db     0x0d, 0x01, 0x04, 0x01, 0x09, 0x04
    .db     0x1e, 0x02
    .db     0x1f, 0x02
    .db           0x1f
    .db     0x01, 0x1f
    .db     0x01, 0x1e, 0x02
    .db           0x1d, 0x04
    .db           0x1b, 0x05
    .db           0x1b, 0x04
    .db           0x1d, 0x03
    .db           0x01, 0x01, 0x1b, 0x04
    .db           0x1b, 0x01, 0x01, 0x03
    .db           0x1d, 0x01
    .db     0x1f, 0x01
    .db     0x1f, 0x02
    .db           0x1f
    .db     0x02, 0x1e
    .db     0x04, 0x09, 0x01, 0x04, 0x01, 0x0d
    .db     0x05, 0x02, 0x02, 0x02, 0x04, 0x01, 0x04, 0x0c
    .db     0x0a, 0x01, 0x0a, 0x05, 0x02, 0x03
    .db     0x21
    .db     0xff

; ページ
titlePatternNamePage:

    .dw     titlePatternNameLogo
    .dw     titlePatternNameMonster0
    .dw     titlePatternNameMonster1
    .dw     titlePatternNameMonster2
    .dw     titlePatternNameItem0
    .dw     titlePatternNameItem1
    .dw     titlePatternNameCondition
    .dw     titlePatternNameIntro

; ロゴ
titlePatternNameLogo:

    .db     0x00, 0x80, 0x00, 0x80
    .db     0x00, 0x13, 0xca, 0xcb, 0xcc, 0xcd, 0x00, 0x09
    .db     0x00, 0x09, 0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xda, 0xdb, 0xdc, 0xdd, 0x00, 0x09
    .db     0x00, 0x09, 0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xea, 0xeb, 0xec, 0xed, 0x00, 0x09
    .db     0x00, 0x09, 0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xfa, 0xfb, 0xfc, 0xfd, 0x00, 0x09
    .db     0x00, 0x09, 0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0x00, 0x01, 0xde, 0xdf, 0xfe, 0x00, 0x09
    .db     0x00, 0x10, 0xce, 0xcf, 0x00, 0x02, 0xee, 0xef, 0xff, 0x00, 0x09
    .db     0x00, 0x40
    .db     0x00, 0x80, 0x00, 0x80

; モンスターその１
titlePatternNameMonster0:

    .db     0x00, 0x62
    .db     0x2d, 0x2f, 0x2e, 0x33, 0x34, 0x25, 0x32, 0x33
    .db     0x00, 0x5e
    .db     0x22, 0x21, 0x34
    .db     0x00, 0x09
    .db     0x2f, 0x32, 0x23
    .db     0x00, 0x51
    .db     0x32, 0x2f, 0x27, 0x36, 0x25
    .db     0x00, 0x07
    .db     0x27, 0x21, 0x32, 0x27, 0x2f, 0x39, 0x2c, 0x25
    .db     0x00, 0x4c
    .db     0x32, 0x25, 0x21, 0x30, 0x25, 0x32
    .db     0x00, 0x06
    .db     0x2c, 0x29, 0x3a, 0x21, 0x32, 0x24
    .db     0x00, 0x4e
    .db     0x2d, 0x21, 0x27, 0x25
    .db     0x00, 0x08
    .db     0x33, 0x2e, 0x21, 0x2b, 0x25
    .db     0x00, 0x4f
    .db     0x27, 0x28, 0x2f, 0x33, 0x34
    .db     0x00, 0x07
    .db     0x24, 0x21, 0x25, 0x2d, 0x2f, 0x2e
    .db     0x00, 0xa6

; モンスターその２
titlePatternNameMonster1:

    .db     0x00, 0x62
    .db     0x2d, 0x2f, 0x2e, 0x33, 0x34, 0x25, 0x32, 0x33
    .db     0x00, 0x5e
    .db     0x33, 0x31, 0x35, 0x29, 0x24
    .db     0x00, 0x07
    .db     0x27, 0x21, 0x3a, 0x25, 0x32
    .db     0x00, 0x4f
    .db     0x33, 0x30, 0x29, 0x24, 0x25, 0x32
    .db     0x00, 0x06
    .db     0x32, 0x21, 0x34
    .db     0x00, 0x51
    .db     0x2d, 0x29, 0x2d, 0x29, 0x23
    .db     0x00, 0x07
    .db     0x33, 0x2c, 0x29, 0x2d, 0x25
    .db     0x00, 0x4f
    .db     0x27, 0x2f, 0x2c, 0x25, 0x2d
    .db     0x00, 0x07
    .db     0x27, 0x28, 0x2f, 0x33, 0x34
    .db     0x00, 0x4f
    .db     0x2c, 0x29, 0x23, 0x28
    .db     0x00, 0x08
    .db     0x30, 0x28, 0x21, 0x2e, 0x34, 0x2f, 0x2d
    .db     0x00, 0xa5

; モンスターその３
titlePatternNameMonster2:

    .db     0x00, 0x62
    .db     0x2d, 0x2f, 0x2e, 0x33, 0x34, 0x25, 0x32, 0x33
    .db     0x00, 0x5f
    .db     0x23, 0x39, 0x23, 0x2c, 0x2f, 0x30, 0x33
    .db     0x00, 0x05
    .db     0x3a, 0x2f, 0x32, 0x2e
    .db     0x00, 0xb0
    .db     0x33, 0x28, 0x21, 0x24, 0x2f, 0x37
    .db     0x00, 0x06
    .db     0x24, 0x32, 0x21, 0x27, 0x2f, 0x2e
    .db     0x00, 0xc1
    .db     0x00, 0xa4

; アイテムその１
titlePatternNameItem0:

    .db     0x00, 0x62
    .db     0x29, 0x34, 0x25, 0x2d, 0x33
    .db     0x00, 0x61
    .db     0x33, 0x37, 0x2f, 0x32, 0x24
    .db     0x00, 0x07
    .db     0x33, 0x28, 0x29, 0x25, 0x2c, 0x24
    .db     0x00, 0x4e
    .db     0x30, 0x2f, 0x34, 0x29, 0x2f, 0x2e
    .db     0x00, 0x06
    .db     0x22, 0x2f, 0x2f, 0x34, 0x33
    .db     0x00, 0x4f
    .db     0x23, 0x2f, 0x2d, 0x30, 0x21, 0x33, 0x33
    .db     0x00, 0x05
    .db     0x2b, 0x25, 0x39
    .db     0x00, 0x51
    .db     0x34, 0x2f, 0x32, 0x23, 0x28
    .db     0x00, 0x07
    .db     0x28, 0x21, 0x2d, 0x2d, 0x25, 0x32
    .db     0x00, 0x4e
    .db     0x23, 0x21, 0x2e, 0x24, 0x2c, 0x25
    .db     0x00, 0x06
    .db     0x2d, 0x29, 0x32, 0x32, 0x2f, 0x32
    .db     0x00, 0xa6

; アイテムその２
titlePatternNameItem1:

    .db     0x00, 0x62
    .db     0x29, 0x34, 0x25, 0x2d, 0x33
    .db     0x00, 0x61
    .db     0x32, 0x29, 0x2e, 0x27
    .db     0x00, 0x08
    .db     0x21, 0x2d, 0x35, 0x2c, 0x25, 0x34
    .db     0x00, 0x4e
    .db     0x21, 0x32, 0x32, 0x2f, 0x37
    .db     0x00, 0x07
    .db     0x24, 0x32, 0x2f, 0x30
    .db     0x00, 0x50
    .db     0x27, 0x32, 0x21, 0x33, 0x33
    .db     0x00, 0x07
    .db     0x24, 0x0e, 0x33, 0x2c, 0x21, 0x39, 0x25, 0x32
    .db     0x00, 0x4c
    .db     0x23, 0x32, 0x39, 0x33, 0x34, 0x21, 0x2c
    .db     0x00, 0x6d
    .db     0x00, 0xa4

; 状態異常
titlePatternNameCondition:

    .db     0x00, 0x62
    .db     0x23, 0x2f, 0x2e, 0x24, 0x29, 0x34, 0x29, 0x2f, 0x2e, 0x33
    .db     0x00, 0x5c
    .db     0x30, 0x2f, 0x29, 0x33, 0x2f, 0x2e
    .db     0x00, 0x06
    .db     0x33, 0x2c, 0x2f, 0x37
    .db     0x00, 0x50
    .db     0x35, 0x2e, 0x30, 0x2f, 0x37, 0x25, 0x32
    .db     0x00, 0x05
    .db     0x35, 0x2e, 0x27, 0x35, 0x21, 0x32, 0x24
    .db     0x00, 0x4d
    .db     0x33, 0x2c, 0x25, 0x25, 0x30
    .db     0x00, 0x07
    .db     0x22, 0x2c, 0x29, 0x2e, 0x24
    .db     0x00, 0x4f
    .db     0x23, 0x2f, 0x2e, 0x26, 0x35, 0x33, 0x25
    .db     0x00, 0x6d
    .db     0x00, 0xa4

; カーソル
titlePatternNameCursor:

    .db     0x1c, 0x0a, 0x1e

; HIT SPACE BAR
titlePatternNameHitSpaceBar:

    .db     0x28, 0x29, 0x34, 0x00, 0x33, 0x30, 0x21, 0x23, 0x25, 0x00, 0x22, 0x21, 0x32
    .db     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

; スプライト
;

; ページ
titleSpritePage:

    .dw     titleSpriteLogo
    .dw     titleSpriteMonster0
    .dw     titleSpriteMonster1
    .dw     titleSpriteMonster2
    .dw     titleSpriteItem0
    .dw     titleSpriteItem1
    .dw     titleSpriteCondition

; ページアニメーション
titleSpritePageAnimation:

    .db     0x00
    .db     0x01
    .db     0x01
    .db     0x02
    .db     0x00
    .db     0x00
    .db     0x00

; ロゴ
titleSpriteLogo:

    .db     0xff

; モンスターその１
titleSpriteMonster0:

    .db     0x30 - 0x01, 0x2c, 0x28, 0x0f
    .db     0x30 - 0x01, 0x8c, 0x2a, 0x0f
    .db     0x48 - 0x01, 0x2c, 0x2c, 0x0f
    .db     0x48 - 0x01, 0x8c, 0x2e, 0x0f
    .db     0x60 - 0x01, 0x2c, 0x30, 0x0f
    .db     0x60 - 0x01, 0x8c, 0x32, 0x0f
    .db     0x78 - 0x01, 0x2c, 0x34, 0x0f
    .db     0x78 - 0x01, 0x8c, 0x36, 0x0f
    .db     0x90 - 0x01, 0x2c, 0x38, 0x0f
    .db     0x90 - 0x01, 0x8c, 0x3a, 0x0f
    .db     0xff

; モンスターその２
titleSpriteMonster1:

    .db     0x30 - 0x01, 0x2c, 0x3c, 0x0f
    .db     0x30 - 0x01, 0x8c, 0x3e, 0x0f
    .db     0x48 - 0x01, 0x2c, 0x40, 0x0f
    .db     0x48 - 0x01, 0x8c, 0x42, 0x0f
    .db     0x60 - 0x01, 0x2c, 0x44, 0x0f
    .db     0x60 - 0x01, 0x8c, 0x46, 0x0f
    .db     0x78 - 0x01, 0x2c, 0x48, 0x0f
    .db     0x78 - 0x01, 0x8c, 0x4a, 0x0f
    .db     0x90 - 0x01, 0x2c, 0x4c, 0x0f
    .db     0x90 - 0x01, 0x8c, 0x4e, 0x0f
    .db     0xff

; モンスターその３
titleSpriteMonster2:

    .db     0x30 - 0x01, 0x24, 0x50, 0x0f
    .db     0x30 - 0x01, 0x34, 0x51, 0x0f
    .db     0x40 - 0x01, 0x24, 0x60, 0x0f
    .db     0x40 - 0x01, 0x34, 0x61, 0x0f
    .db     0x30 - 0x01, 0x84, 0x54, 0x0f
    .db     0x30 - 0x01, 0x94, 0x55, 0x0f
    .db     0x40 - 0x01, 0x84, 0x64, 0x0f
    .db     0x40 - 0x01, 0x94, 0x65, 0x0f
    .db     0x60 - 0x01, 0x24, 0x58, 0x0f
    .db     0x60 - 0x01, 0x34, 0x59, 0x0f
    .db     0x70 - 0x01, 0x24, 0x68, 0x0f
    .db     0x70 - 0x01, 0x34, 0x69, 0x0f
    .db     0x60 - 0x01, 0x84, 0x5c, 0x0f
    .db     0x60 - 0x01, 0x94, 0x5d, 0x0f
    .db     0x70 - 0x01, 0x84, 0x6c, 0x0f
    .db     0x70 - 0x01, 0x94, 0x6d, 0x0f
    .db     0xff

; アイテムその１
titleSpriteItem0:

    .db     0x30 - 0x01, 0x2c, 0x10, 0x0f
    .db     0x30 - 0x01, 0x8c, 0x11, 0x0f
    .db     0x48 - 0x01, 0x2c, 0x12, 0x0f
    .db     0x48 - 0x01, 0x8c, 0x13, 0x0f
    .db     0x60 - 0x01, 0x2c, 0x14, 0x0f
    .db     0x60 - 0x01, 0x8c, 0x15, 0x0f
    .db     0x78 - 0x01, 0x2c, 0x16, 0x0f
    .db     0x78 - 0x01, 0x8c, 0x17, 0x0f
    .db     0x90 - 0x01, 0x2c, 0x18, 0x0f
    .db     0x90 - 0x01, 0x8c, 0x19, 0x0f
    .db     0xff

; アイテムその２
titleSpriteItem1:

    .db     0x30 - 0x01, 0x2c, 0x1a, 0x0f
    .db     0x30 - 0x01, 0x8c, 0x1b, 0x0f
    .db     0x48 - 0x01, 0x2c, 0x1c, 0x0f
    .db     0x48 - 0x01, 0x8c, 0x1d, 0x0f
    .db     0x60 - 0x01, 0x2c, 0x1e, 0x0f
    .db     0x60 - 0x01, 0x8c, 0x1f, 0x0f
    .db     0x78 - 0x01, 0x2c, 0x20, 0x0f
    .db     0xff

; 状態異常
titleSpriteCondition:

    .db     0x30 - 0x01, 0x2c, 0x80, 0x0f
    .db     0x30 - 0x01, 0x8c, 0x81, 0x0f
    .db     0x48 - 0x01, 0x2c, 0x82, 0x0f
    .db     0x48 - 0x01, 0x8c, 0x83, 0x0f
    .db     0x60 - 0x01, 0x2c, 0x84, 0x0f
    .db     0x60 - 0x01, 0x8c, 0x85, 0x0f
    .db     0x78 - 0x01, 0x2c, 0x86, 0x0f
    .db     0xff

; サウンド
;

; BGM
titleSoundBgm0:

    .ascii  "T2V15-3L8"
    .ascii  "O5EO4BFEABO5CD"
    .ascii  "O5EDCO4BABO5CO4B"
    .ascii  "O4AR"
    .db     0xff

titleSoundBgm1:

    .ascii  "T2V15-3L8"
    .ascii  "O4EDCDEDCD"
    .ascii  "O4EDCDEDCD"
    .ascii  "O4CR"
    .db     0xff
    
titleSoundBgm2:

    .ascii  "T2V15-3L8"
    .ascii  "O3AGFEAGFE"
    .ascii  "O3AGFEAGFE"
    .ascii  "O3FR"
    .db     0xff

; フェード
titleSoundFade:

    .ascii  "T1V16S4M5N7X5X5"
    .db     0x00

; クリック
titleSoundClick:

    .ascii  "T1V15O4B0"
    .db     0x00

; ゲームスタート
titleSoundStart:

    .ascii  "T1V15L3O6BO5BR9"
    .db     0x00


; DATA 領域
;
    .area   _DATA

; 変数の定義
;

; タイトル
;
_title::
    
    .ds     TITLE_LENGTH