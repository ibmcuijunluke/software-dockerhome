
def gettags = ("git ls-remote -h git@gitlab.brandwisdom.cn:j_cui/jw-automation.git").execute()
gettags.text.readLines().collect { it.split()[1].replaceAll('refs/heads/', '')  }.unique()
defver_keys = [ 'bash', '-c', 'cd /gitsource/springMVC; git pull>/dev/null; git branch -a|grep -v "*" | grep -v ">"|cut -d "/" -f3|sort -r |head -10 ' ]
ver_keys.execute().text.tokenize('\n')
def gettags = ("git ls-remote -h git@gitlab.brandwisdom.cn:j_cui/jw-automation.git").execute()
gettags.text.readLines().collect { it.split()[1].replaceAll('refs/heads/', '')  }.unique()


#excute automation testing framework
#author cuijun 20161128

cd $WORKSPACE
cd jw_testcase
python testsuit_interface.py


find /opt/apache-packages/ -name "*.sql" -exec rm -rf {} \;

find /opt/jwsqldir/ -name "*.sql" | xargs -i cp {} /opt/apache-packages/
echo "move sql files has been done"
