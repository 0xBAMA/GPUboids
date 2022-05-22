#include "engine.h"

bool engine::mainLoop() {
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

void engine::clear() {
	// clear the screen
	glClearColor( clearColor.x, clearColor.y, clearColor.z, clearColor.w ); // from hsv picker
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

void engine::computePasses() {

	// dispatch boids update w/ atomic writes
	glUseProgram( boidShader );
	glUniform1f( glGetUniformLocation( boidShader, "time" ), SDL_GetTicks() / 100.0 );
	glDispatchCompute( sqrtNumBoids / 16 + 1, sqrtNumBoids / 16 + 1, 1 );
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

	// dispatch bake pass
	// glUseProgram( bakeShader );
	// glDispatchCompute( writeBufferSize / 16, writeBufferSize / 16, 1 );
	// glMemoryBarrier( GL_SHADER_IMAGE_ACCESS_BARRIER_BIT );

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
	}
}
