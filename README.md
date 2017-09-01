# SwipeSpeak

SwipeSpeak is an iPhone app that allows people to communicate with eye gestures. The **_communication partner_** reads eye gestures of the **_speaker_** and swipes in the corresponding direction on the phone screen. SwipeSpeak will then translate those swipes into words and sentences. We strongly recommend printing the <a href="assets/files/keyboard.pdf">keyboard layout image file</a> and taping it somewhere that speakers can see for easy reference. The communication partner can also attach the keyboard on his/her clothes, make an apron with keyboard print, or insert the keyboard in a transparent binder.</p>

<a href="">
<img src="assets/images/AppStore.png" width="200px" alt="App Store Download Button">
</a>

SwipeSpeak is an open-source project created by <a href="http://www.teamgleason.org/"/>Team Gleason</a>. Please keep in mind that it is a **_research prototype_** rather than a polished commercial product; we hope that the community finds value in the new interaction style embodied by this app and continues to improve it via the open-source project.

# Typing with SwipeSpeak

<img src="/assets/images/typing_TASK.jpg" alt="Word Predictions Update After Each Gesture in This Four-gesture Sequence to Spell TASK." width="80%">

**Figure 1. Word predictions update after each gesture in this four-gesture sequence to spell "task".**

To reduce fatigue and increase throughput, our app uses four simple eye gestures (up/down/left/right) to refer to all 26 letters of the English alphabet, using only one gesture per letter entered. This design leads to an ambiguous keyboard (Figure 1.a) in which the letters of the alphabet are clustered into four groups that can each be indicated with one up/down/left/right gesture. On the back of the phone, a four-key image reminds the speaker of the letter groupings associated with each of the four gesture directions; you can print the keyboard layout image file and tape it to the back of your phone for easy reference by the speaker. SwipeSpeak also supports multiple keyboard layouts, each having a different number of possible eye gesture directions (Figure 2.b).

Our app implements a predictive text engine to find all possible words that could be created with the letters in the groups indicated by a gesture sequence. To enter one character, the speaker moves his eyes in the direction associated with that letter’s group; the communication partner swipes in corresponding direction on the phone screen. For example, to enter the word TASK (Figure 1.b), the speaker first looks down for T, then looks up for A, looks right for S, and looks left for K.

<br>
<br>
<br>

<img src="/assets/images/typing_interface.png" alt="Communication Partner Interface." width="80%">

**Figure 2. Communication Partner Interface.** (<a href="/assets/files/Typing.mp4">Demo Video</a>)

In the following instructions, we use "wink left eye" as no, and "wink right eye" as yes. Speakers and their communication partners can use their own agreed-upon eye gestures for yes/no.

When the speaker mistypes a letter, he can wink left eye to notify the communication partner, who can then touch the backspace key to correct it.

When the speaker finishes a sequence for an entire word, he can wink right eye to notify the communication partner, who can then touch each prediction so that the system will speak it aloud. The speaker can wink right eye again to confirm this prediction, or wink left eye to reject. The communication partner can long press the confirmed prediction to add it to the current sentence, and begin accepting gestures for the next word.

When it feels like the end of a sentence, the communication partner can touch the sentence box to let SwipeSpeak read the entire sentence aloud. The sentence box will be empty after reading.

When the speaker rejects all word predictions, please read the instructions on entering "Out-of-Dictionary Words" below.

The communication partner can touch the gear icon to access settings to switch between alternative keyboard layouts, add out-of-dictionary words and see previously entered sentences.

<br>
<br>
<br>

<img src="/assets/images/typing_out.png" alt="Build an Out-of-dictionary Word.">

**Figure 3. Build an Out-of-dictionary Word.** (<a href="/assets/files/Out.mp4">Demo Video</a>)

After typing with several gestures, the desired word may not be in the set of word predictions (Figure 3.a); this is particularly likely for unique words such as proper nouns (e.g., a person’s name). In this case, the communication partner can touch the orange "Build Word" button to allow the speaker to confirm the word, letter by letter.

To build a word, SwipeSpeak will use the most recent gesture sequence before hitting the "Build Word" button. Then, for each gesture in the sequence, SwipeSpeak will read all letters in the key associated with that eye gesture direction. When the desired letter is spoken, the speaker uses a gesture to confirm the letter. The communication partner sees the confirmation gesture and touches the "Confirm" button. The communication partner can touch the "Cancel" button any time to restart typing if the speaker indicates the word is wrong (Figure 3.b).

For example, the speaker looks Up, Right, Down, but does not see the desired word "Amy" in the word predictions. Then, in "Build Word" mode, the speaker will first hear "<b>A</b>, B, C, D, E, F", a letter at a time. When he hears "A", the speaker should confirm the first letter (Figure 3.c). Then the speaker will hear "<b>M</b>, N, O, P, Q, R, S". When he hears "M", the speaker should confirm the second letter. Finally, the speaker will hear "T, U, V, W, X, <b>Y</b>, Z" (Figure 3.d). When hears "Y", the speaker should confirm the last letter (Figure 3.e).

When the speaker confirms all letters of the desired word, it will be added to the prediction dictionary for future re-use. The communication partner can also manually add words to the prediction dictionary in "Settings -> User-added words". Our prediction dictionary only includes ~5000 common words. The interpreter can add words frequently used by the speaker, so that those words will be shown in word predictions during typing with SwipeSpeak. Please do not include punctuation or spaces in the new words.
