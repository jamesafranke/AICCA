import os
import numpy as np
import pyarrow as pa
import torch
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers

class Sampling(layers.Layer):
    """Uses (z_mean, z_log_var) to sample z, the vector encoding a digit."""
    def call(self, inputs):
        z_mean, z_log_var = inputs
        batch = tf.shape(z_mean)[0]
        dim = tf.shape(z_mean)[1]
        epsilon = tf.keras.backend.random_normal(shape=(batch, dim))
        return z_mean + tf.exp(0.5 * z_log_var) * epsilon

latent_dim = 50
nl = 3
ld = 2048

encoder_inputs = keras.Input( shape = (512, 512, 1) )
x = layers.Conv2D(32, nl, activation="relu", strides=2, padding="same")(encoder_inputs)
x = layers.Conv2D(64, nl, activation="relu", strides=2, padding="same")(x)
x = layers.Conv2D(128, nl, activation="relu", strides=2, padding="same")(x)
x = layers.Conv2D(256, nl, activation="relu", strides=2, padding="same")(x)
x = layers.Conv2D(512, nl, activation="relu", strides=2, padding="same")(x)
x = layers.Conv2D(1024, nl, activation="relu", strides=2, padding="same")(x)
x = layers.Flatten()(x)
x = layers.Dense(ld, activation="relu")(x)
z_mean = layers.Dense(latent_dim, name="z_mean")(x)
z_log_var = layers.Dense(latent_dim, name="z_log_var")(x)
z = Sampling()([z_mean, z_log_var])
encoder = keras.Model(encoder_inputs, [z_mean, z_log_var, z], name="encoder")
#encoder.summary()

latent_inputs = keras.Input( shape=(latent_dim,) )
x = layers.Dense(8 * 8 * 1024, activation="relu")(latent_inputs)
x = layers.Reshape( (8, 8, 1024) )(x)
x = layers.Conv2DTranspose(1024, nl, activation="relu", strides=2, padding="same")(x)
x = layers.Conv2DTranspose(512, nl, activation="relu", strides=2, padding="same")(x)
x = layers.Conv2DTranspose(256, nl, activation="relu", strides=2, padding="same")(x)
x = layers.Conv2DTranspose(128, nl, activation="relu", strides=2, padding="same")(x)
x = layers.Conv2DTranspose(64, nl, activation="relu", strides=2, padding="same")(x)
x = layers.Conv2DTranspose(32, nl, activation="relu", strides=2, padding="same")(x)
decoder_outputs = layers.Conv2DTranspose(1, nl, activation="sigmoid", padding="same")(x)
decoder = keras.Model(latent_inputs, decoder_outputs, name="decoder")
#decoder.summary()

class VAE(keras.Model):
    def __init__(self, encoder, decoder, **kwargs):
        super(VAE, self).__init__(**kwargs)
        self.encoder = encoder
        self.decoder = decoder
        self.total_loss_tracker = keras.metrics.Mean( name="total_loss" )
        self.reconstruction_loss_tracker = keras.metrics.Mean( name="reconstruction_loss" )
        self.kl_loss_tracker = keras.metrics.Mean( name="kl_loss" )

    @property
    def metrics(self):
        return [self.total_loss_tracker, self.reconstruction_loss_tracker, self.kl_loss_tracker ]

    def train_step(self, data):
        with tf.GradientTape() as tape:
            z_mean, z_log_var, z = self.encoder(data)
            reconstruction = self.decoder(z)
            reconstruction_loss = tf.reduce_mean(  tf.reduce_sum( keras.losses.binary_crossentropy(data, reconstruction), axis=(1, 2)) )
            kl_loss = -0.5 * (1 + z_log_var - tf.square(z_mean) - tf.exp(z_log_var))
            kl_loss = tf.reduce_mean(tf.reduce_sum(kl_loss, axis=1))
            total_loss = reconstruction_loss + kl_loss
        
        grads = tape.gradient(total_loss, self.trainable_weights)
        self.optimizer.apply_gradients(zip(grads, self.trainable_weights))
        self.total_loss_tracker.update_state(total_loss)
        self.reconstruction_loss_tracker.update_state(reconstruction_loss)
        self.kl_loss_tracker.update_state(kl_loss)
        return {
            "loss": self.total_loss_tracker.result(),
            "reconstruction_loss": self.reconstruction_loss_tracker.result(),
            "kl_loss": self.kl_loss_tracker.result(),
        }


imstack = pa.ipc.read_tensor(f'{root}training_stack.npy' )


vae = VAE( encoder, decoder )
vae.compile( optimizer = keras.optimizers.Adam() )
vae.fit( imstack, epochs = 10, batch_size = 50 )