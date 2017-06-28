JAZZY=$(which jazzy)
if [ $? != 0 ]; then
    echo -e "Jazzy is required to generate documentation. Install it with:\n"
    echo -e "    gem install jazzy\n"
    exit
fi

jazzy -x -workspace,CNLDataProvider.xcworkspace,-scheme,CNLDataProvider -a Complex\ Numbers -o ./Docs --sdk iphoneos --documentation=./*.md --github_url https://github.com/megavolt605/CNLDataProvider --theme fullwidth