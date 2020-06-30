## HW 7. Operator, CustomResourceDefinition

To get it running in your cluster

```shell script
cd ./deploy
kubectl apply -f service-account.yml \
-f role.yml \
-f role-binding.yml \
-f deploy-operator.yml \
-f crd.yml \
-f cr.yml
```

Make sure that `pvc` resources have been created

```shell script
kubectl get pvc
```

Add some data to the `mysql-instance`

```shell script
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
kubectl exec -it $MYSQLPOD -- mysql -uroot -potuspassword -e "CREATE TABLE test ( id smallint unsigned not null auto_increment, name varchar(20) not null, constraint pk_example primary key (id) );" otus-database
kubectl exec -it $MYSQLPOD -- mysql -uroot -potuspassword -e "INSERT INTO test ( id, name ) VALUES ( null, 'some data' );" otus-database
kubectl exec -it $MYSQLPOD -- mysql -uroot -potuspassword -e "INSERT INTO test ( id, name ) values ( null, 'some data-2' );" otus-database
```

check that the database has been modified

```shell script
kubectl exec -it $MYSQLPOD -- mysql -uroot -potuspassword -e "SELECT * from test;" otus-database
```

Delete `mysql-instance` and make sure that `pv` resource has been removed from the cluster, and `jobs.batch` resource has been completed

```shell script
kubectl delete mysqls.otus.homework mysql-instance
```

Wait for a little while and recreate `mysql-instance` custom resource

```shell script
kubectl apply -f cr.yml
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
kubectl exec -it $MYSQLPOD -- mysql -uroot -potuspassword -e "SELECT * from test;" otus-database
```

The output should look similar to this

```shell script
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
```

Run `kubectl get jobs` and the output should look similar to this

```
NAME                         COMPLETIONS   DURATION   AGE
backup-mysql-instance-job    1/1           1s         14m
restore-mysql-instance-job   1/1           6m17s      17m
```
