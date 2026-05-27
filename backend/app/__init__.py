import sys

try:
    import tf_keras
    import tensorflow as tf
    import keras._tf_keras.keras.layers as compatibility_layers

    compatibility_layers.LocallyConnected2D = tf_keras.layers.LocallyConnected2D
    sys.modules["tensorflow.keras.layers.LocallyConnected2D"] = tf_keras.layers.LocallyConnected2D
    tf.keras.layers.LocallyConnected2D = tf_keras.layers.LocallyConnected2D
except Exception:
    pass

