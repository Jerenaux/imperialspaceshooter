# Imperial Space Shooter

A five-round arcade shooter made with Godot 4. Open `project.godot` in Godot and press **F5** or run `godot --path .`.

**Play in your browser:** https://jerenaux.github.io/imperialspaceshooter/

- Move with **WASD** or **arrow keys**; hold **Space** to fire.
- Each enemy destroyed earns **10 credits**. Spend credits on rapid fire or thrusters between rounds.
- You have **three lives per round**. Losing all three restarts the current round; credits and upgrades carry over.
- Clear round five to win, then choose **Play Again** for a fresh run.

Run the gameplay check with `godot --headless --path . --script test_game.gd` after Godot has imported the project.

Each push to `main` exports the Web build and publishes it through GitHub Pages.
