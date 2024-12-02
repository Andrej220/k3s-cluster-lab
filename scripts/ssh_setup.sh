#!/bin/bash
set -e
echo "Setting up SSH..."
systemctl enable ssh
systemctl start ssh
echo "SSH setup completed."