# SwipeSpeak

SwipeSpeak is an iPhone app that allows people with locked-in syndrome (**_speakers_**) to communicate. The **_communication partner_** reads eye gestures of speakers and swipes in corresponding direction on phone screen. Then SwipeSpeak will translate those swipes into words and sentences.

<a href="">
<img src="assets/images/AppStore.png" width="200px" alt="App Store Download Button">
</a>

SwipeSpeak is an open-source project created by <a href="https://www.microsoft.com/en-us/research/group/enable"/>Microsoft Research Enable Team</a> and <a href="http://www.teamgleason.org/"/>Team Gleason</a>. Please keep in mind that it is a **_research prototype_** rather than a polished commercial product; we hope that the community finds value in the new interaction style embodied by this app and continues to improve it via the open source project.

# Start Typing

<img src="/assets/images/typing_TASK.jpg" alt="Word Predictions Update After Each Gesture in This Four-gesture Sequence to Spell TASK." width="80%">

**Figure 1. Word Predictions Update After Each Gesture in This Four-gesture Sequence to Spell "task".**

To reduce fatigue and increase throughput, our app uses four simple eye gestures (up/down/left/right) to refer to all 26 letters of the English alphabet, using only one gesture per letter entered. This design leads to an ambiguous keyboard (Figure 1.a) in which the letters of the alphabet are clustered into four groups that can each be indicated with one up/down/left/right gesture. On the back of the phone, a four-key image reminds the speaker of the letter groupings associated with each of the four gesture directions; you can print the keyboard layout image file and tape it to the back of your phone for easy reference by the speaker. SwipeSpeak also supports multiple keyboards layout with different number of possible eye gesture directions (Figure 2.b).

Our app implements a predictive text engine to find all possible words that could be created with the letters in the groups indicated by a gesture sequence. To enter one character, the speaker moves his eyes in the direction associated with that letter’s group; the communication partner swipes in corresponding direction on phone screen. For example, to enter the word TASK (Figure 1.b), the speaker first looks down for T, then looks up for A, looks right for S, and looks left for K.

<br>
<br>
<br>

<img src="/assets/images/typing_interface.png" alt="Communication Partner Interface." width="80%">

**Figure 2. Communication Partner Interface.**

In the following instruction, we use "wink left eye" as no, and "wink right eye" as yes. Speakers and their communication partners can use their own agreed-upon eye gestures for yes/no.

When the speaker mistypes a letter, he can wink left eye to notify the communication partner, who can then touch the backspace key to correct it.

When the speaker finishes a sequence for an entire word, he can wink right eye to notify the communication partner, who can then touch each prediction so that the system will speak it aloud. The speaker can wink right eye again to confirm this prediction, or wink left eye to reject. The communication partner can long press the confirmed prediction to add it to the current sentence, and begin accepting gestures for the next word.

When it feels like the end of a sentence, the communication partner can touch the sentence box to let SwipeSpeak read the entire sentence aloud. The sentence box will be empty after reading.

When the speaker rejects all word predictions, please read the "Out-of-Dictionary Words" on the top bar for solution.

The communication partner can touch the gear icon to access settings.
