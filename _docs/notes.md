YouAreHistory is an interactive edutainment web application.

The core concept is that users/players will watch an animation which puts them in the shoes of a character from history - such as mediaeval merchants, Renaissance sailors, Regency servants - and talk them through an scene from that person's life.

At certain points in the story, it will pause and ask the player to decide which path to take. Each decision will be educational and highlight something critical or interesting about the period of focus. The idea is that through inhabiting this perspective and being forced to make these decisions, players will engage with the period more fully.

Each story will have up to three 'advisors' - when a decision is being made, the player can consult them for additional context (for instance, a mediaeval healer woman can consult the local priest for a religious view, a monastic scholar to learn about the "science" of the era)

If the player chooses wrong, they will see an animation of the consequences. If configured with branching paths, it will continue down the chose path. If the path is a dead-end and not marked as 'final', then it will "rewind" and continue down the correct path. 

As the player is making their decision, a short animation will loop to make sure the screen remains alive

This will continue until the player reaches a "final" state, at which point they will see a summary of the decisions they've made scored (i.e 1/3). Note that the rewind mechanic allows them to progress, but it DOESN'T mean they get the point for it (the intiial decision is all that's scored)


The core framework for this should be a very simple state machine with a simple configuration syntax. Each choice will be binary. The animations will be pre-rendered .mp4 files to begin with - the audio will be built into them. For now, the assets and state machine config can be hard-coded.

To begin with the user interface will be:
* A box containing the video reaching from the top-left to about 3/4 the game window.
* A bar along the bottom, which contains the binary choice buttons and some short text to supplement the voiceover about what decision to make.
* A sidebar in which the advisors can be selected and their advice shows up as text. 


The initial example for this will be a mediaeval healer woman. She has two decisions to make, both of which have right and wrong answers. The wrong answers will not be final, so if taken the animation will play and we rewind to the decision. At the end, the score pops up on screen. The videos should be named as part of the state machine config file, but they'll be healer_intro, healer_decision_1_loop, healer_decision_1_wrong, healer_decision_1_correct, healer_decision_2_loop, healer_decision_2_wrong, healer_decision_2_correct, healer_final