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
    float   ball_outter_distance = 3.4;//should bigger than ball_radius_inner + ball_radius_outter
    
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
        float frequencyHz = 30;
        float damping = 0.5f;
        
 
        
        
        //用joint连接所有ball
        
         b2DistanceJointDef joint;
         
         joint.Initialize(current_ball, neighbor_ball,
         current_ball->GetWorldCenter(),
         neighbor_ball->GetWorldCenter() );
         joint.collideConnected = true;
//         joint.frequencyHz = 0;
//         joint.dampingRatio = damping;/
         
         world->CreateJoint(&joint);
         
         // Connect the center circle with other circles
         joint.Initialize(current_ball, m_inner_ball, current_ball->GetWorldCenter(), m_inner_ball->GetWorldCenter());
         joint.collideConnected = true;
         joint.frequencyHz = frequencyHz;
         joint.dampingRatio = damping;
         
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



ccVertex3F make_vec( float x, float y)
{
    ccVertex3F v;
    v.x = x;
    v.y = y;
    v.z = 0;
    return v;
}

ccTex2F make_uv( float x, float y)
{
    ccTex2F v;
    v.u = x;
    v.v = y;
    return v;
}

-(void) draw
{
    //顶点数据
    
    
    CGPoint pos = ccp( [self nodeToParentTransform].tx, [self nodeToParentTransform].ty);
    
    //设置扇形中心点坐标
    m_vertices[0].vertices = make_vec( m_inner_ball->GetPosition().x * PTM_RATIO - pos.x, m_inner_ball->GetPosition().y * PTM_RATIO  - pos.y );
    //设置扇形中心点uv
    m_vertices[0].texCoords = make_uv(0.5f, 0.5f);
    m_vertices[0].colors = ccc4(255, 255, 255, 50);
    
    for ( int i = 0; i < m_num_segment; i++ )
    {
        b2Body *current_ball = m_outter_balls[i];
        m_vertices[i+1].vertices = make_vec( current_ball->GetPosition().x * PTM_RATIO  - pos.x, current_ball->GetPosition().y * PTM_RATIO  - pos.y );
        GLfloat rad =  CC_DEGREES_TO_RADIANS(360.0f/m_num_segment * i);
        m_vertices[i+1].texCoords = make_uv( 0.5+cosf(rad)*0.5, 0.5+sinf(rad)*-0.5   );
        m_vertices[i+1].colors = ccc4(255, 255, 255, 50);
    }
    
    //封闭扇形
    m_vertices[m_num_segment+1] = m_vertices[1];
    
    //设置gl渲染环境
	CC_NODE_DRAW_SETUP();
    
	ccGLBlendFunc( blendFunc_.src, blendFunc_.dst );
    
	ccGLBindTexture2D( [texture_ name] );
    
	//
	// Attributes
	//
    
	ccGLEnableVertexAttribs( kCCVertexAttribFlag_PosColorTex  );
    
	// vertex
	NSInteger diff = offsetof( ccV3F_C4B_T2F, vertices);
	glVertexAttribPointer(kCCVertexAttrib_Position, 3, GL_FLOAT, GL_FALSE, sizeof(ccV3F_C4B_T2F), (void*) ((char*)m_vertices + diff));
    
	// texCoods
	diff = offsetof( ccV3F_C4B_T2F, texCoords);
	glVertexAttribPointer(kCCVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, sizeof(ccV3F_C4B_T2F), (void*)((char*)m_vertices+ diff));
    
	// color
	diff = offsetof( ccV3F_C4B_T2F, colors);
	glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(ccV3F_C4B_T2F), (void*)((char*)m_vertices + diff));
    
    
    
	glDrawArrays(GL_TRIANGLE_FAN, 0, m_num_segment + 2);
    
	CHECK_GL_ERROR_DEBUG();
    
    
}

-(void) dealloc
{
	// 
	[super dealloc];
}

@end
