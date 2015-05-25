#import "MainScene.h"
@interface MainScene()

@property (strong) CCTiledMap *tileMap;
@property (strong) CCNode *scroll;

@property (strong) CCTiledMapLayer *background;
@property (strong) CCSprite *player;
@property (strong) CCTiledMapLayer *meta;
@property (strong) CCTiledMapLayer *foreground;
//@property (strong) HudLayer *hud;
@property(strong) CCLabelTTF *hudlabel;
@property (assign) int numCollected;

@end
@implementation MainScene
- (void)setViewPointCenter:(CGPoint) position {
    
    CGSize winSize = [CCDirector sharedDirector].viewSize;
    
    int x = MAX(position.x, winSize.width/2);
    int y = MAX(position.y, winSize.height/2);
    x = MIN(x, (_tileMap.mapSize.width * _tileMap.tileSize.width) - winSize.width / 2);
    y = MIN(y, (_tileMap.mapSize.height * _tileMap.tileSize.height) - winSize.height/2);
    CGPoint actualPosition = ccp(x, y);
    
    CGPoint centerOfView = ccp(winSize.width/2, winSize.height/2);
    CGPoint viewPoint = ccpSub(centerOfView, actualPosition);
    self.scroll.position = viewPoint;/*was self*/
}

- (void)didLoadFromCCB {
    self.tileMap = [CCTiledMap tiledMapWithFile:@"TileMap.tmx"];
    self.background = [_tileMap layerNamed:@"Background"];
    self.foreground = [_tileMap layerNamed:@"Foreground"];
    
    self.meta = [_tileMap layerNamed:@"Meta"];
    _meta.visible = NO;
    CCTiledMapObjectGroup *objectGroup = [_tileMap objectGroupNamed:@"Objects"];
    NSAssert(objectGroup != nil, @"tile map has no objects object layer");
    
    NSDictionary *spawnPoint = [objectGroup objectNamed:@"SpawnPoint"];
    int x = [spawnPoint[@"x"] integerValue];
    int y = [spawnPoint[@"y"] integerValue];
    
    _player = [CCSprite spriteWithImageNamed:@"Player.png"];
    _player.position = ccp(x,y);
    
    [_scroll addChild:_player];
    [self setViewPointCenter:_player.position];
    
    [_scroll addChild:_tileMap z:-1];
    self.userInteractionEnabled = TRUE;
    [[OALSimpleAudio sharedInstance] playBg:@"TileMap.caf" loop:true];
    [self numCollectedChanged:0];


}

- (CGPoint)tileCoordForPosition:(CGPoint)position {
    int x = position.x / _tileMap.tileSize.width;
    int y = ((_tileMap.mapSize.height * _tileMap.tileSize.height) - position.y) / _tileMap.tileSize.height;
    return ccp(x, y);
}
-(void)numCollectedChanged:(int)numCollected
{
    _hudlabel.string = [NSString stringWithFormat:@"%d",numCollected];
}
-(void)setPlayerPosition:(CGPoint)position {
    
    CGPoint tileCoord = [self tileCoordForPosition:position];
    int tileGid = [_meta tileGIDAt:tileCoord];
    if (tileGid) {
        NSDictionary *properties = [_tileMap propertiesForGID:tileGid];
        if (properties) {
            
            NSString *collision = properties[@"Collidable"];
            if (collision && [collision isEqualToString:@"True"]) {
                 [[OALSimpleAudio sharedInstance] playEffect:@"hit.caf"];
                return;
            }
            
            NSString *collectible = properties[@"Collectable"];
            if (collectible && [collectible isEqualToString:@"True"]) {
                [[OALSimpleAudio sharedInstance] playEffect:@"pickup.caf"];
                self.numCollected++;
//                [_hud numCollectedChanged:_numCollected];
                  [self numCollectedChanged:_numCollected];

                
                [_meta removeTileAt:tileCoord];
                [_foreground removeTileAt:tileCoord];
            }
        }
    }
    [[OALSimpleAudio sharedInstance] playEffect:@"move.caf"];
    _player.position = position;
}

- (void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
}
- (void)touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    CGPoint touchLocation = [touch locationInNode:_scroll];
    CGPoint playerPos = _player.position;
    CGPoint diff = ccpSub(touchLocation, playerPos);
    
    if ( fabsf(diff.x) > fabsf(diff.y) ) {
        if (diff.x > 0) {
            playerPos.x += _tileMap.tileSize.width;
        } else {
            playerPos.x -= _tileMap.tileSize.width;
        }
    } else {
        if (diff.y > 0) {
            playerPos.y += _tileMap.tileSize.height;
        } else {
            playerPos.y -= _tileMap.tileSize.height;
        }
    }
    
    CCLOG(@"playerPos %@",CGPointCreateDictionaryRepresentation(playerPos));
    
    // safety check on the bounds of the map
    if (playerPos.x <= (_tileMap.mapSize.width * _tileMap.tileSize.width) &&
        playerPos.y <= (_tileMap.mapSize.height * _tileMap.tileSize.height) &&
        playerPos.y >= 0 &&
        playerPos.x >= 0 )
    {
        [self setPlayerPosition:playerPos];
    }
    
    [self setViewPointCenter:_player.position];

}
@end
