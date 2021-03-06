#include "engine.h"

bool engine::mainLoop() {
	// update simulation parameters
	sendSimParams();

	// compute passes
	computePasses();

	// clear the screen and depth buffer
	clear();

	// fullscreen triangle copying the image
	mainDisplay();

	// do all the gui stuff
	imguiPass();

	// swap the double buffers to present
	SDL_GL_SwapWindow( window );

	// handle all events
	handleEvents();

	// break main loop when pQuit turns true
	return pQuit;
}

void engine::sendSimParams() {
	// glUniform1f( glGetUniformLocation( boidShader, "" ), );
	glUseProgram( displayShader );
	glUniform1f( glGetUniformLocation( displayShader, "outputRangeScalar" ), sp.outputRangeScalar );

	glUseProgram( boidShader );
	glUniform1f( glGetUniformLocation( boidShader, "zoomFactor" ), sp.zoomFactor );
	glUniform1f( glGetUniformLocation( boidShader, "senseDistance" ), sp.senseDistance );
	glUniform1f( glGetUniformLocation( boidShader, "alignmentForceScalar" ), sp.alignmentForceScalar );
	glUniform1f( glGetUniformLocation( boidShader, "separationForceScalar" ), sp.separationForceScalar );
	glUniform1f( glGetUniformLocation( boidShader, "cohesionForceScalar" ), sp.cohesionForceScalar );
	glUniform2i( glGetUniformLocation( boidShader, "computeDimensions" ), sqrtNumBoids, sqrtNumBoids );
	glUniformMatrix3fv( glGetUniformLocation( boidShader, "rotationMatrix" ), 1, GL_FALSE, glm::value_ptr( sp.rotationMatrix ) );

	glUseProgram( blurShader );
	glUniform1f( glGetUniformLocation( blurShader, "decayFactor" ), sp.decayFactor );
}

void engine::clear() {
	// clear the screen
	glClearColor( clearColor.x, clearColor.y, clearColor.z, clearColor.w ); // from hsv picker
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

void engine::computePasses() {

	// dispatch boids update w/ atomic writes
	glUseProgram( boidShader );
	glUniform1f( glGetUniformLocation( boidShader, "time" ), SDL_GetTicks() / 100.0 );
	glDispatchCompute( sqrtNumBoids / 16, sqrtNumBoids / 16, 1 );
	glMemoryBarrier( GL_SHADER_IMAGE_ACCESS_BARRIER_BIT );

	// swap current and previous buffers
	std::swap( colorAccumulate[ 0 ], colorAccumulate[ 3 ] );
	std::swap( colorAccumulate[ 1 ], colorAccumulate[ 4 ] );
	std::swap( colorAccumulate[ 2 ], colorAccumulate[ 5 ] );
	// rebind, in the swapped positions
	for( int i = 1; i < 7; i++ )
		glBindImageTexture( i, colorAccumulate[ i - 1 ], 0, GL_FALSE, 0, GL_READ_WRITE, GL_R32UI );

	// dispatch blur pass
	glUseProgram( blurShader );
	// glDispatchCompute( writeBufferSize / 16, writeBufferSize / 16, 1 );
	glDispatchCompute( ( totalScreenWidth / 16 ) + 1, ( totalScreenHeight / 16 ) + 1, 1 );
	glMemoryBarrier( GL_SHADER_IMAGE_ACCESS_BARRIER_BIT );

	// ready to present
}

void engine::mainDisplay() {
	// texture display
	ImGuiIO &io = ImGui::GetIO();
	glUseProgram( displayShader );
	glBindVertexArray( displayVAO );
	glUniform2f( glGetUniformLocation( displayShader, "resolution" ), io.DisplaySize.x, io.DisplaySize.y );
	glDrawArrays( GL_TRIANGLES, 0, 3 );
}

void engine::imguiPass() {
	// start the imgui frame
	imguiFrameStart();

	// show quit confirm window
	quitConf( &quitConfirm );

	// controls window
	paramWindow();

	// finish up the imgui stuff and put it in the framebuffer
	imguiFrameEnd();
}

void engine::handleEvents() {
	SDL_Event event;
	while ( SDL_PollEvent( &event ) ) {
		// imgui event handling
		ImGui_ImplSDL2_ProcessEvent( &event );

		if ( event.type == SDL_QUIT )
			pQuit = true;

		if ( event.type == SDL_WINDOWEVENT && event.window.event == SDL_WINDOWEVENT_CLOSE && event.window.windowID == SDL_GetWindowID( window ) )
			pQuit = true;

		if ( ( event.type == SDL_KEYUP && event.key.keysym.sym == SDLK_ESCAPE) || ( event.type == SDL_MOUSEBUTTONDOWN && event.button.button == SDL_BUTTON_X1 ))
			quitConfirm = !quitConfirm; // x1 is browser back on the mouse

		if ( event.type == SDL_KEYUP && event.key.keysym.sym == SDLK_ESCAPE && SDL_GetModState() & KMOD_SHIFT )
			pQuit = true; // force quit on shift+esc ( bypasses confirm window )

		// quaternion based rotation via retained state in the basis vectors - much easier to use than the arbitrary euler angles
		if( event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_UP ) {
			glm::quat rot = glm::angleAxis( SDL_GetModState() & KMOD_SHIFT ? -0.1f : -0.005f, glm::vec3( 1.0, 0.0, 0.0 ) );
			sp.rotationMatrix = glm::toMat3( rot ) * sp.rotationMatrix;
		}
		if( event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_DOWN ) {
			glm::quat rot = glm::angleAxis( SDL_GetModState() & KMOD_SHIFT ?  0.1f :  0.005f, glm::vec3( 1.0, 0.0, 0.0 ) );
			sp.rotationMatrix = glm::toMat3( rot ) * sp.rotationMatrix;
		}
		if( event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_LEFT ) {
			glm::quat rot = glm::angleAxis( SDL_GetModState() & KMOD_SHIFT ? -0.1f : -0.005f, glm::vec3( 0.0, 1.0, 0.0 ) );
			sp.rotationMatrix = glm::toMat3( rot ) * sp.rotationMatrix;
		}
		if( event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_RIGHT ) {
			glm::quat rot = glm::angleAxis( SDL_GetModState() & KMOD_SHIFT ?  0.1f :  0.005f, glm::vec3( 0.0, 1.0, 0.0 ) );
			sp.rotationMatrix = glm::toMat3( rot ) * sp.rotationMatrix;
		}

		if ( event.type == SDL_MOUSEWHEEL ) {
			if ( event.wheel.y > 0 ) {
				sp.zoomFactor *= 1.1;
			} else if ( event.wheel.y < 0 ) {
				sp.zoomFactor *= 0.9;
			}
		}
	}
}
