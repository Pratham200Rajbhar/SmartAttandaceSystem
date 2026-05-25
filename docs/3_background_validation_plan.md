You have reached the final computer vision module of your AI Core!

Background Validation is the module that ensures a student isn't just a real human (`Liveness`), but that they are actually **inside the classroom** and not marking attendance from their bed or a coffee shop.

Here is the hard truth about this specific module: **You cannot download this dataset from Kaggle or the web.** Because this AI needs to recognize *your specific college campus* or *your specific classrooms*, a generic web dataset of random classrooms won't work. If you train it on Kaggle data, it will approve anyone sitting in any room with a whiteboard, which defeats the purpose of location validation.

Here is the exact strategy to build this dataset yourself, quickly and effectively.

### 1. The Directory Structure

First, set up your folders inside `ai_core/3_background_validation/`. You are building a binary classifier (Valid Location vs. Invalid Location).

```text
3_background_validation/
├── data/
│   ├── valid_campus/    # Photos inside the actual classrooms/labs
│   └── invalid_out/     # Photos of bedrooms, cafes, cars, streets

```

### 2. How to Collect the `valid_campus` Data

You and your team need to take a walk around your college.

* **Go to the target classrooms:** Take photos of the rooms where this system will be used.
* **Capture the defining features:** Ensure the photos include the college's specific desks, whiteboards, projector screens, or unique wall colors.
* **Vary the angles:** Take pictures from the front row, the back row, looking at the windows, and looking at the door.
* **Target Quantity:** Aim for about **150 to 200 photos** of the valid campus locations.

### 3. How to Collect the `invalid_out` Data

This is the easier part. You need to teach the AI what *not* to accept.

* Take photos of your own bedrooms, living rooms, and kitchens.
* Take photos at a local coffee shop or restaurant.
* Take photos outside on the street or in a car.
* **Target Quantity:** Aim for **150 to 200 photos** of these invalid locations.

*Shortcut:* For the `invalid_out` folder, you *can* technically use a web dataset of random bedroom/cafe backgrounds if you don't want to take 200 photos yourself, but the `valid_campus` data must be strictly from your real college.

### 4. The AI Strategy (Good News)

Because we just used **TensorFlow and MobileNetV2** for your Liveness Detection module, you already know exactly how to build this AI!

MobileNetV2 is incredible at recognizing background textures and room layouts. We will use the exact same Transfer Learning architecture from Module 2, just swapping the data folders.

Are you ready to grab your phone and snap those classroom photos, or would you like me to adapt the MobileNetV2 Jupyter Notebook code for this specific background validation task so it is ready when you get back?