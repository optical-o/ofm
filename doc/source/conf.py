# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
import os
import sys
sys.path.append(os.path.abspath("./_ext"))
#sys.path.insert(0, os.path.abspath('.'))
#print(sys.path)
import sphinx_rtd_theme
from pathlib import Path

# -- Project information -----------------------------------------------------

project = 'OFM User Guide'
copyright = '2021, CESNET z.s.p.o.'
author = 'CESNET TMC'

# The full version, including alpha/beta/rc tags
release = '1.0'

# -- General configuration ---------------------------------------------------

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    "ofm",
    "sphinx_rtd_theme",
    "sphinxvhdl.vhdl"
]

vhdl_autodoc_source_path = (Path(__file__).parent.parent.parent / 'comp').resolve()

# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = []


# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = "sphinx_rtd_theme"
#html_theme = 'classic'
#html_theme_options = {
#	"sidebarwidth" : "15%",
#	"body_max_width" : "82.4%",
#	"body_min_width" : "550px",
#	"stickysidebar" : "true"
#}

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['_static']

html_style = 'css/theme_overrides.css'
