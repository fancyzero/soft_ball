//
//  PhysicsSprite.h
//  cocos2d-ios
//
//  Created by Ricardo Quesada on 1/4/12.
//  Copyright (c) 2012 Zynga. All rights reserved.
//

#import "cocos2d.h"
#import "Box2D.h"

@interface soft_ball : CCNode
{
	b2Body  *m_inner_ball;
    b2Body  *m_outter_balls[1024];
    int     m_num_segment;
}

-(void) init_physics:( b2World* ) world :(int) num_segment;
@end