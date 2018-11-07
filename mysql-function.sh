# mysql_config --version
mysql_v(){
    # ./Cellar/mariadb@10.1/10.1.36/bin/mysql
    mysql_version=$(ls -al /usr/local/bin/mysql)
    mysql_v_str=${mysql_version#*Cellar/}
    mysql_v=${mysql_v_str%%/*}
    old_mysql=$mysql_v
}

mysql_list_func(){
    mysql_v
    mysql_list=$(brew list | egrep "mysql@|mariadb@")
    for i in $mysql_list
    do
        if [ "$i" = "$old_mysql" ]; then
            echo -e "*\033[41;37m $i \033[0m"
        else
            echo '  '$i;
        fi
    done
}

check_mysql_version(){
    mysql_list_func

    case $1 in
        10.0|10.1|10.2|10.3)
            creat_delete_link $1 'mariadb'
        ;;

        5.7|5.6|5.5)
            creat_delete_link $1 'mysql'
        ;;

        *)
            if [ 0"$1" != "0" ]; then
                echo '请输入正确的版本号！';
            fi
    esac

    if [ 0"$1" != "0" ]; then
        mysql_list_func
        msg="版本切换完成!请在命令行执行 mysql -V 查看mysql版本"
        echo -e "\n*\033[41;37m $msg \033[0m\n"
    fi
}

get_mysql_v_int(){
    mysql_version=$(mysql -V | sed s/[[:space:]]//g)
    m_v=${mysql_version#*Distrib}
    mysql_v=${m_v%%-MariaDB*}
    mysql_v_int=${mysql_v%.*}
}

creat_delete_link(){
    # 第一步：停止当前运行的mysql版本
    # 第二步：删除（/usr/local/Cellar/mariadb）软连接
    # 第三步：创建（/usr/local/Cellar/mariadb）软连接
    # 第四步：删除并创建（brew unlink mariadb@10.1 && brew link mariadb@10.0 --force）软连接
    # 第五步：启动mysql服务（brew services start mariadb@10.0）
    brew services stop $old_mysql
    mysql_name=$2
    new_mysql=$mysql_name'@'$1
    rm -rf '/usr/local/var/mysql'
    ln -s '/usr/local/var/mysql_'$1  '/usr/local/var/mysql'

    rm -rf '/usr/local/Cellar/'$mysql_name
    ln -s '/usr/local/Cellar/'$new_mysql  '/usr/local/Cellar/mariadb'

    rm -rf '/usr/local/opt/'$mysql_name
    ln -s '/usr/local/Cellar/'$new_mysql  '/usr/local/opt/'$mysql_name
    
    export LDFLAGS="-L/usr/local/opt/$new_mysql/lib"
    export CPPFLAGS="-I/usr/local/opt/$new_mysql/include"
    export PKG_CONFIG_PATH="/usr/local/opt/$new_mysql/share/pkgconfig"

    brew unlink $old_mysql
    brew link $new_mysql --force | grep 'Linking'
    brew services start $new_mysql
    touch /tmp/mysql.sock

    ls -al '/usr/local/var/mysql'
    ls -al '/usr/local/Cellar/'$mysql_name
    ls -al '/usr/local/bin/mysql'
}

#匹配内容并替换
replace_zshrc_mysql_v(){
    if [ 0"$1" != "0" ]; then
        get_mysql_v_int
        mysql_v_str='mariadb\@'$mysql_v_int
        perl -pi -e "s|$mysql_v_str|mariadb\@$1|gi" ~/.zshrc
    fi
}