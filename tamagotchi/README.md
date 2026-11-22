# 🐸 Taskbar Tamagotchi

A simple virtual pet that lives in your taskbar.
It passively runs while you use your computer, changing its mood over time based on basic needs like hunger, energy, cleanliness, and happiness.

Each placed instance uses its own effective configuration and existing native
game fields. Views of the same instance share one Main-owned game; opening
another view does not start another timer. Plugin-level actions and the
background game remain plugin-level. Retiring an instance stops its game and
refuses queued actions. Settings never resets or migrates stored game state.
The original integer stat conversion, random factors and 30-second cadence are
preserved; this is not a change to game difficulty or decay formulas.

---

## 🧠 How it works

The pet gradually changes state depending on how well it’s taken care of.
If ignored for too long, it becomes sad, tired, or angry.
If maintained, it stays calm and healthy.

---

## 🎮 Interaction

You can occasionally:

- Feed it
- Let it sleep
- Clean it
- Play with it

No constant attention required — just check in from time to time.

---

## ❤️ Special Thanks

BTW the frog's name is **Forgy**, created by my girlfriend, **Lu Bollati** — thank you for bringing so much personality and charm into this little creature.
There’s something really special about seeing your art turn into something alive on screen.

I love you deeply, and this project carries a piece of that with it.
