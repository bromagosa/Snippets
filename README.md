# Snippets: not exactly a web template system

Snippets is Not (In Principle) a Perfect, Exhaustive Template System

# Build System

Snippets uses a page descriptor system designed to be super simple and save you from copy-pasting any HTML around. Here's how it works:

* The `build.sh` script reads all `.snp` page descriptor files from the `/pages` directory and builds each HTML page accordingly, giving it the same name as the descriptor file.
* Page descriptors define a page by enumerating what templates (chunks of HTML) should compose the page.
* Multiple templates can be concatenated together by placing them in the same line, separated by semicolons.
* Template names in the descriptor file are matched against files under the `/templates` directory.
* Templates are plain HTML files with a `.tmp` extension that may or may not define a `@content` placeholder.
* Templates may include an `@include=name` directive. `@include`s should be on their own line, and `name` should be the base name of another template file.
    * Included templates will also resolve any parameters.
    * Nested or recursive includes are supported.
* If said placeholder exists, the templates found in the next line of the descriptor file are going to be rendered into it.
* Parameters in a page descriptor file are defined one per line by following the pattern `@param myparameter=myvalue`. Multi-word values should be enclosed by double quotes.
* Access these parameters in `.tmp` files by prefixing them with a dollar sign and, optionally, enclosing them between curly brackets, as in `$myparameter` or `${myparameter}`.
* The generated pages are stored in the `www` folder.
* You should place any other files into `static`, such as Javascript files, images or stylesheets. These will be copied over into the resulting `www` folder.

## Usage

    ./build [--watch] [--serve]

`--watch` will keep an eye at all files in your project tree and rebuild it if it detects any changes. This makes for a live-reload experience.

`--serve` will attempt to start a webserver on your `www` folder, making your built project accessible at `http://localhost:8080`. For this feature to work you'll need a working installation of either Ruby, Python (2+), PHP or the NodeJS `http-server` module.

## Example

Given the following files:

**pages/test.snp**

    base
    @param name="Example Person"
    welcome;examples
    example1;example2;example3

**templates/base.tmp**

    <html>
        <head><title>An example page</title></head>
        <body>
            @content
            @include=footer
        </body>
    </html>

**templates/welcome.tmp**

    <h1>Welcome to this test site, ${name}!</h1>
    <p>This is just an example site to show you how the page descriptor system works.</p>
    <img src="img/logo.png">

**templates/examples.tmp**

    <div>
        <h2>Here's a couple of embedded templates:</h2>
        @content
    </div>

**templates/example1.tmp**

    <span>First One</span>

**templates/example2.tmp**

    <span>Second One</span>

**templates/example3.tmp**

    <span>Third One</span>

**templates/footer.tmp**

    <p>Thanks for checking out my site.</p>

**static/img/logo.png**

![example image](https://github.com/bromagosa/Snippets/blob/master/static/img/logo.png?raw=true)

Running `./build.sh` will generate the file:

**www/test.html**

    <html>
        <head><title>An example page</title></head>
        <body>
            <h1>Welcome to this test site, Example Person!</h1>
            <p>This is just an example site to show you how the page descriptor system works.</p>
            <img src="img/logo.png">
            <div>
                <h2>Here's a couple of embedded templates:</h2>
                <span>First One</span>
                <span>Second One</span>
                <span>Third One</span>
            </div>
            <p>Thanks for checking out my site.</p>
        </body>
    </html>

# In the Wild

Snippets is not being used anymore. In the past, the MicroBlocks site (a small one) and the Snap! community site (a reasonably big and complex one) were built using Snippets, but we've graduated both of them to more mature systems.  Snippets was a fun experiment, but I don't recommend using it unless it's just for fun and giggles, or for your very small website.

The moral of the story is that you may not want to build a full static site generator in Bash, and if you do, it may not take "just a weekend" and do everything you'll ever need it to do.

Though I'm a big fan of reinventing wheels and I think you should always reinvent your own, this one particular wheel was not fit for the 18-wheeler tractor trailer that the Snap! site ended up being :)
