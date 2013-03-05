//
//  PhysicsSprite.mm
//  soft_ball
//
//  Created by FancyZero on 13-3-5.
//  Copyright __MyCompanyName__ 2013年. All rights reserved.
//


#import "PhysicsSprite.h"

// Needed PTM_RATIO
#import "HelloWorldLayer.h"

#pragma mark - soft_ball
@implementation soft_ball

-(b2Body*) create_ball: (b2World*) world :(const b2Vec2&) pos  :(float) radius_in_physics_unit
{
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
	bodyDef.position = pos;
	b2Body *body = world->CreateBody(&bodyDef);
    b2CircleShape ball;
    ball.m_p = b2Vec2(0,0);
    ball.m_radius = radius_in_physics_unit;
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &ball;
	fixtureDef.density = 1.0f;
	fixtureDef.friction = 0.3f;
	body->CreateFixture(&fixtureDef);
    body->SetFixedRotation(true);
    return body;
}

-(void) init_physics:( b2World* ) world :(int) num_segment;
{
    //define our contants
    float   ball_radius_inner = 1.0f;
    float   ball_radius_outter = 0.2f;
    float   ball_outter_distance = 1.5;

    m_num_segment = num_segment;
    b2Vec2 pos = b2Vec2(position_.x/PTM_RATIO, position_.y/PTM_RATIO);
    m_inner_ball = [self create_ball: world :pos :ball_radius_inner ];

    
    
    for ( int i = 0; i < num_segment; i++ )
    {
        float x_offset = cosf(CC_DEGREES_TO_RADIANS(i*(360.0f/num_segment)));
        float y_offset = sinf(CC_DEGREES_TO_RADIANS(i*(360.0f/num_segment)));
        
        m_outter_balls[i] = [self create_ball: world :b2Vec2( pos.x + x_offset * ball_outter_distance, pos.y + y_offset * ball_outter_distance ) :ball_radius_outter ];
        
    }
    
    for ( int i = 0; i < num_segment; i++ )
    {
        int neighbor = (i + 1) % num_segment;
        b2Body *current_ball = m_outter_balls[i];
        b2Body *neighbor_ball = m_outter_balls[neighbor];
        float frequencyHz = 10;
        // Connect the outer circles to each other
        b2DistanceJointDef joint;
        
        joint.Initialize(current_ball, neighbor_ball,
                         current_ball->GetWorldCenter(),
                         neighbor_ball->GetWorldCenter() );
        joint.collideConnected = true;
        joint.frequencyHz = frequencyHz;
        joint.dampingRatio = 0.5f;
        
        world->CreateJoint(&joint);
        
        // Connect the center circle with other circles
        joint.Initialize(current_ball, m_inner_ball, current_ball->GetWorldCenter(), m_inner_ball->GetWorldCenter());
        joint.collideConnected = true;
        joint.frequencyHz = frequencyHz;
        joint.dampingRatio = 0.5;
        
        world->CreateJoint(&joint);
        
    }
}


// this method will only get called if the sprite is batched.
// return YES if the physics values (angles, position ) changed
// If you return NO, then nodeToParentTransform won't be called.
-(BOOL) dirty
{
	return YES;
}

// returns the transform matrix according the Chipmunk Body values
-(CGAffineTransform) nodeToParentTransform
{	
	b2Vec2 pos  = m_inner_ball->GetPosition();
	
	float x = pos.x * PTM_RATIO;
	float y = pos.y * PTM_RATIO;
	
	if ( ignoreAnchorPointForPosition_ ) {
		x += anchorPointInPoints_.x;
		y += anchorPointInPoints_.y;
	}
	
	// Make matrix
	float radians = m_inner_ball->GetAngle();
	float c = cosf(radians);
	float s = sinf(radians);
	
	if( ! CGPointEqualToPoint(anchorPointInPoints_, CGPointZero) ){
		x += c*-anchorPointInPoints_.x + -s*-anchorPointInPoints_.y;
		y += s*-anchorPointInPoints_.x + c*-anchorPointInPoints_.y;
	}
	
	// Rot, Translate Matrix
	transform_ = CGAffineTransformMake( c,  s,
									   -s,	c,
									   x,	y );	
	
	return transform_;
}

-(void) dealloc
{
	// 
	[super dealloc];
}

@end
