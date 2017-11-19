module main::analysis::DataSet

import Prelude;
import lang::java::m3::Core;
import main::Util;

alias Library = tuple[int id, str organisation, str name, str revision, str cpFile, list[str] libFiles];

public list[int libraryId] smallLibraries = [2..99] - [3] - [25];


public list[Library] TestDataSet = 
[
	<0, "org.scala-lang", "scala-compiler", "2.10.4", "org.scala-lang/scala-compiler/jars/scala-compiler-2.10.4.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.scala-lang/scala-library/jars/scala-library-2.10.4.jar",
		"org.scala-lang/scala-reflect/jars/scala-reflect-2.10.4.jar"]>,
	<1, "org.scala-lang", "scala-library", "2.10.4", "org.scala-lang/scala-library/jars/scala-library-2.10.4.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<2, "junit", "junit", "4.12", "junit/junit/jars/junit-4.12.jar", [
		"java-8-openjdk-amd64/jre/lib/", 
		"org.hamcrest/hamcrest-core/jars/hamcrest-core-1.3.jar"]>,
	<3, "org.scala-lang", "scala-library", "2.12.0-M3", "org.scala-lang/scala-library/jars/scala-library-2.12.0-M3.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<4, "org.slf4j", "slf4j-api", "1.7.12", "org.slf4j/slf4j-api/jars/slf4j-api-1.7.12.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<5, "log4j", "log4j", "1.2.17", "log4j/log4j/bundles/log4j-1.2.17.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<6, "com.google.guava", "guava", "19.0-rc2", "com.google.guava/guava/bundles/guava-19.0-rc2.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<7, "ch.qos.logback", "logback-classic", "1.1.3", "ch.qos.logback/logback-classic/jars/logback-classic-1.1.3.jar", [
	    "ch.qos.logback/logback-core/jars/logback-core-1.1.3.jar", // Added myself
		"java-8-openjdk-amd64/jre/lib/"]>,
	<8, "commons-io", "commons-io", "2.4", "commons-io/commons-io/jars/commons-io-2.4.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<9, "org.slf4j", "slf4j-log4j12", "1.7.12", "org.slf4j/slf4j-log4j12/jars/slf4j-log4j12-1.7.12.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.slf4j/slf4j-api/jars/slf4j-api-1.7.12.jar",
		"log4j/log4j/bundles/log4j-1.2.17.jar"]>,
	<10, "org.mockito", "mockito-all", "1.10.19", "org.mockito/mockito-all/jars/mockito-all-1.10.19.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<11, "org.apache.commons", "commons-lang3", "3.4", "org.apache.commons/commons-lang3/jars/commons-lang3-3.4.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<12, "commons-logging", "commons-logging", "1.2", "commons-logging/commons-logging/jars/commons-logging-1.2.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<13, "org.testng", "testng", "6.9.9", "org.testng/testng/jars/testng-6.9.9.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"com.beust/jcommander/jars/jcommander-1.48.jar",
		"com.google.inject/guice/jars/guice-4.0.jar",
		"javax.inject/javax.inject/jars/javax.inject-1.jar",
		"aopalliance/aopalliance/jars/aopalliance-1.0.jar",
		"org.yaml/snakeyaml/bundles/snakeyaml-1.15.jar",
		"org.beanshell/bsh/jars/bsh-2.0b4.jar"]>,
	<14, "org.apache.maven", "maven-plugin-api", "3.3.3", "org.apache.maven/maven-plugin-api/jars/maven-plugin-api-3.3.3.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.apache.maven/maven-model/jars/maven-model-3.3.3.jar",
		"org.apache.maven/maven-artifact/jars/maven-artifact-3.3.3.jar",
		"org.eclipse.sisu/org.eclipse.sisu.plexus/eclipse-plugins/org.eclipse.sisu.plexus-0.3.0.jar",
		"org.eclipse.sisu/org.eclipse.sisu.inject/eclipse-plugins/org.eclipse.sisu.inject-0.3.0.jar",
		"org.codehaus.plexus/plexus-component-annotations/jars/plexus-component-annotations-1.5.5.jar",
		"org.codehaus.plexus/plexus-classworlds/bundles/plexus-classworlds-2.5.2.jar"]>,
	<15, "org.springframework", "spring-context", "4.2.2.RELEASE", "org.springframework/spring-context/jars/spring-context-4.2.2.RELEASE.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.springframework/spring-aop/jars/spring-aop-4.2.2.RELEASE.jar",
		"aopalliance/aopalliance/jars/aopalliance-1.0.jar",
		"org.springframework/spring-beans/jars/spring-beans-4.2.2.RELEASE.jar",
		"org.springframework/spring-core/jars/spring-core-4.2.2.RELEASE.jar",
		"commons-logging/commons-logging/jars/commons-logging-1.2.jar",
		"org.springframework/spring-expression/jars/spring-expression-4.2.2.RELEASE.jar"]>,
	<16, "org.apache.httpcomponents", "httpclient", "4.5.1", "org.apache.httpcomponents/httpclient/jars/httpclient-4.5.1.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"commons-logging/commons-logging/jars/commons-logging-1.2.jar"]>,
	<17, "org.osgi", "org.osgi.core", "6.0.0", "org.osgi/org.osgi.core/jars/org.osgi.core-6.0.0.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<18, "joda-time", "joda-time", "2.9", "joda-time/joda-time/jars/joda-time-2.9.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<19, "javax.servlet", "javax.servlet-api", "3.1.0", "javax.servlet/javax.servlet-api/jars/javax.servlet-api-3.1.0.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<20, "com.fasterxml.jackson.core", "jackson-databind", "2.6.3", "com.fasterxml.jackson.core/jackson-databind/bundles/jackson-databind-2.6.3.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"com.fasterxml.jackson.core/jackson-core/bundles/jackson-core-2.6.3.jar"]>,
	<21, "commons-codec", "commons-codec", "1.10", "commons-codec/commons-codec/jars/commons-codec-1.10.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<22, "org.springframework", "spring-test", "4.2.2.RELEASE", "org.springframework/spring-test/jars/spring-test-4.2.2.RELEASE.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.springframework/spring-core/jars/spring-core-4.2.2.RELEASE.jar",
		"commons-logging/commons-logging/jars/commons-logging-1.2.jar"]>,
	<23, "org.springframework", "spring-core", "4.2.2.RELEASE", "org.springframework/spring-core/jars/spring-core-4.2.2.RELEASE.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"commons-logging/commons-logging/jars/commons-logging-1.2.jar"]>,
	<24, "org.easymock", "easymock", "3.4", "org.easymock/easymock/jars/easymock-3.4.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.objenesis/objenesis/jars/objenesis-2.2.jar"]>,
	<25, "org.scalatest", "scalatest_2.10", "3.0.0-M11", "org.scalatest/scalatest_2.10/bundles/scalatest_2.10-3.0.0-M11.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.scalactic/scalactic_2.10/bundles/scalactic_2.10-3.0.0-M11.jar",
		"org.scala-lang/scala-reflect/jars/scala-reflect-2.10.5.jar"]>,
	<26, "commons-collections", "commons-collections", "3.2.1", "commons-collections/commons-collections/jars/commons-collections-3.2.1.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<27, "org.codehaus.plexus", "plexus-utils", "3.0.22", "org.codehaus.plexus/plexus-utils/jars/plexus-utils-3.0.22.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<28, "com.h2database", "h2", "1.4.190", "com.h2database/h2/jars/h2-1.4.190.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<29, "org.apache.maven", "maven-project", "2.2.1", "org.apache.maven/maven-project/jars/maven-project-2.2.1.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.apache.maven/maven-profile/jars/maven-profile-2.2.1.jar",
		"org.apache.maven/maven-artifact-manager/jars/maven-artifact-manager-2.2.1.jar",
		"org.apache.maven.wagon/wagon-provider-api/jars/wagon-provider-api-1.0-beta-6.jar",
		"backport-util-concurrent/backport-util-concurrent/jars/backport-util-concurrent-3.1.jar",
		"org.apache.maven/maven-plugin-registry/jars/maven-plugin-registry-2.2.1.jar"]>,
	<30, "com.google.code.gson", "gson", "2.4", "com.google.code.gson/gson/jars/gson-2.4.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<31, "org.osgi", "org.osgi.compendium", "5.0.0", "org.osgi/org.osgi.compendium/jars/org.osgi.compendium-5.0.0.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<32, "org.springframework", "spring-beans", "4.2.2.RELEASE", "org.springframework/spring-beans/jars/spring-beans-4.2.2.RELEASE.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.springframework/spring-core/jars/spring-core-4.2.2.RELEASE.jar",
		"commons-logging/commons-logging/jars/commons-logging-1.2.jar"]>,
	<33, "com.google.code.findbugs", "jsr305", "3.0.1", "com.google.code.findbugs/jsr305/jars/jsr305-3.0.1.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<34, "org.codehaus.jackson", "jackson-mapper-asl", "1.9.13", "org.codehaus.jackson/jackson-mapper-asl/jars/jackson-mapper-asl-1.9.13.jar", [
		"java-8-openjdk-amd64/jre/lib/","org.codehaus.jackson/jackson-core-asl/jars/jackson-core-asl-1.9.13.jar"]>,
	<35, "org.hamcrest", "hamcrest-library", "1.3", "org.hamcrest/hamcrest-library/jars/hamcrest-library-1.3.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.hamcrest/hamcrest-core/jars/hamcrest-core-1.3.jar"]>,
	<36, "org.springframework", "spring-web", "4.2.2.RELEASE", "org.springframework/spring-web/jars/spring-web-4.2.2.RELEASE.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.springframework/spring-aop/jars/spring-aop-4.2.2.RELEASE.jar",
		"aopalliance/aopalliance/jars/aopalliance-1.0.jar",
		"org.springframework/spring-beans/jars/spring-beans-4.2.2.RELEASE.jar",
		"org.springframework/spring-core/jars/spring-core-4.2.2.RELEASE.jar",
		"commons-logging/commons-logging/jars/commons-logging-1.2.jar",
		"org.springframework/spring-context/jars/spring-context-4.2.2.RELEASE.jar",
		"org.springframework/spring-expression/jars/spring-expression-4.2.2.RELEASE.jar"]>,
	<37, "com.fasterxml.jackson.core", "jackson-core", "2.6.3", "com.fasterxml.jackson.core/jackson-core/bundles/jackson-core-2.6.3.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<38, "com.google.inject", "guice", "4.0", "com.google.inject/guice/jars/guice-4.0.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"javax.inject/javax.inject/jars/javax.inject-1.jar",
		"aopalliance/aopalliance/jars/aopalliance-1.0.jar"]>,
	<39, "org.codehaus.groovy", "groovy-all", "2.4.5", "org.codehaus.groovy/groovy-all/jars/groovy-all-2.4.5.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<40, "org.apache.maven", "maven-core", "3.3.3", "org.apache.maven/maven-core/jars/maven-core-3.3.3.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.apache.maven/maven-model/jars/maven-model-3.3.3.jar",
		"org.apache.maven/maven-settings/jars/maven-settings-3.3.3.jar",
		"org.apache.maven/maven-settings-builder/jars/maven-settings-builder-3.3.3.jar",
		"org.apache.maven/maven-builder-support/jars/maven-builder-support-3.3.3.jar",
		"org.codehaus.plexus/plexus-interpolation/jars/plexus-interpolation-1.21.jar",
		"org.codehaus.plexus/plexus-component-annotations/jars/plexus-component-annotations-1.5.5.jar",
		"org.sonatype.plexus/plexus-sec-dispatcher/jars/plexus-sec-dispatcher-1.3.jar",
		"org.apache.maven/maven-repository-metadata/jars/maven-repository-metadata-3.3.3.jar",
		"org.apache.maven/maven-artifact/jars/maven-artifact-3.3.3.jar",
		"org.apache.maven/maven-plugin-api/jars/maven-plugin-api-3.3.3.jar",
		"org.eclipse.sisu/org.eclipse.sisu.plexus/eclipse-plugins/org.eclipse.sisu.plexus-0.3.0.jar",
		"org.eclipse.sisu/org.eclipse.sisu.inject/eclipse-plugins/org.eclipse.sisu.inject-0.3.0.jar",
		"org.codehaus.plexus/plexus-classworlds/bundles/plexus-classworlds-2.5.2.jar",
		"org.apache.maven/maven-model-builder/jars/maven-model-builder-3.3.3.jar",
		"org.apache.maven/maven-aether-provider/jars/maven-aether-provider-3.3.3.jar",
		"org.eclipse.aether/aether-api/jars/aether-api-1.0.2.v20150114.jar",
		"org.eclipse.aether/aether-spi/jars/aether-spi-1.0.2.v20150114.jar",
		"org.eclipse.aether/aether-util/jars/aether-util-1.0.2.v20150114.jar",
		"org.eclipse.aether/aether-impl/jars/aether-impl-1.0.2.v20150114.jar"]>,
	<41, "org.hamcrest", "hamcrest-core", "1.3", "org.hamcrest/hamcrest-core/jars/hamcrest-core-1.3.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<42, "commons-beanutils", "commons-beanutils", "1.9.2", "commons-beanutils/commons-beanutils/jars/commons-beanutils-1.9.2.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"commons-collections/commons-collections/jars/commons-collections-3.2.1.jar"]>,
	<43, "ch.qos.logback", "logback-core", "1.1.3", "ch.qos.logback/logback-core/jars/logback-core-1.1.3.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<44, "com.google.gwt", "gwt-user", "2.7.0", "com.google.gwt/gwt-user/jars/gwt-user-2.7.0.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<45, "mysql", "mysql-connector-java", "5.1.37", "mysql/mysql-connector-java/jars/mysql-connector-java-5.1.37.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<46, "org.springframework", "spring-webmvc", "4.2.2.RELEASE", "org.springframework/spring-webmvc/jars/spring-webmvc-4.2.2.RELEASE.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.springframework/spring-beans/jars/spring-beans-4.2.2.RELEASE.jar",
		"org.springframework/spring-core/jars/spring-core-4.2.2.RELEASE.jar",
		"commons-logging/commons-logging/jars/commons-logging-1.2.jar",
		"org.springframework/spring-context/jars/spring-context-4.2.2.RELEASE.jar",
		"org.springframework/spring-aop/jars/spring-aop-4.2.2.RELEASE.jar",
		"aopalliance/aopalliance/jars/aopalliance-1.0.jar",
		"org.springframework/spring-expression/jars/spring-expression-4.2.2.RELEASE.jar",
		"org.springframework/spring-web/jars/spring-web-4.2.2.RELEASE.jar"]>,
	<47, "com.fasterxml.jackson.core", "jackson-annotations", "2.6.3", "com.fasterxml.jackson.core/jackson-annotations/bundles/jackson-annotations-2.6.3.jar", [	
		"java-8-openjdk-amd64/jre/lib/"]>,
	<48, "javax.enterprise", "cdi-api", "2.0-EDR1", "javax.enterprise/cdi-api/jars/cdi-api-2.0-EDR1.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"javax.el/javax.el-api/jars/javax.el-api-3.0.0.jar",
		"javax.interceptor/javax.interceptor-api/jars/javax.interceptor-api-1.2.jar",
		"javax.inject/javax.inject/jars/javax.inject-1.jar"]>,
	<49, "commons-cli", "commons-cli", "1.3.1", "commons-cli/commons-cli/jars/commons-cli-1.3.1.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<50, "javax.mail", "mail", "1.4.7", "javax.mail/mail/jars/mail-1.4.7.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"javax.activation/activation/jars/activation-1.1.jar"]>,
	<51, "org.assertj", "assertj-core", "3.2.0", "org.assertj/assertj-core/bundles/assertj-core-3.2.0.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"junit/junit/jars/junit-4.12.jar",
		"org.hamcrest/hamcrest-core/jars/hamcrest-core-1.3.jar"]>,
	<52, "org.apache.ant", "ant", "1.9.6", "org.apache.ant/ant/jars/ant-1.9.6.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.apache.ant/ant-launcher/jars/ant-launcher-1.9.6.jar"]>,
	<53, "xerces", "xercesImpl", "2.11.0", "xerces/xercesImpl/jars/xercesImpl-2.11.0.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<54, "org.hibernate", "hibernate-core", "5.0.3.Final", "org.hibernate/hibernate-core/jars/hibernate-core-5.0.3.Final.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.jboss.logging/jboss-logging/jars/jboss-logging-3.3.0.Final.jar",
		"org.hibernate.javax.persistence/hibernate-jpa-2.1-api/jars/hibernate-jpa-2.1-api-1.0.0.Final.jar",
		"antlr/antlr/jars/antlr-2.7.7.jar","org.jboss/jandex/bundles/jandex-2.0.0.CR1.jar",
		"org.apache.geronimo.specs/geronimo-jta_1.1_spec/jars/geronimo-jta_1.1_spec-1.1.1.jar",
		"dom4j/dom4j/jars/dom4j-1.6.1.jar",
		"org.hibernate.common/hibernate-commons-annotations/jars/hibernate-commons-annotations-5.0.0.Final.jar"]>,
	<55, "org.apache.maven", "maven-artifact", "3.3.3", "org.apache.maven/maven-artifact/jars/maven-artifact-3.3.3.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<56, "org.apache.derby", "derby", "10.12.1.1", "org.apache.derby/derby/jars/derby-10.12.1.1.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<57, "org.hsqldb", "hsqldb", "2.3.3", "org.hsqldb/hsqldb/jars/hsqldb-2.3.3.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<58, "org.hibernate", "hibernate-entitymanager", "5.0.3.Final", "org.hibernate/hibernate-entitymanager/jars/hibernate-entitymanager-5.0.3.Final.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.jboss.logging/jboss-logging/jars/jboss-logging-3.3.0.Final.jar",
		"org.hibernate/hibernate-core/jars/hibernate-core-5.0.3.Final.jar",
		"org.hibernate.javax.persistence/hibernate-jpa-2.1-api/jars/hibernate-jpa-2.1-api-1.0.0.Final.jar",
		"antlr/antlr/jars/antlr-2.7.7.jar",
		"org.jboss/jandex/bundles/jandex-2.0.0.CR1.jar",
		"org.apache.geronimo.specs/geronimo-jta_1.1_spec/jars/geronimo-jta_1.1_spec-1.1.1.jar",
		"dom4j/dom4j/jars/dom4j-1.6.1.jar",
		"org.hibernate.common/hibernate-commons-annotations/jars/hibernate-commons-annotations-5.0.0.Final.jar"]>,
	<59, "org.freemarker", "freemarker", "2.3.23", "org.freemarker/freemarker/jars/freemarker-2.3.23.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<60, "javax.validation", "validation-api", "1.1.0.Final", "javax.validation/validation-api/jars/validation-api-1.1.0.Final.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<61, "cglib", "cglib-nodep", "3.2.0", "cglib/cglib-nodep/jars/cglib-nodep-3.2.0.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<62, "org.springframework", "spring-jdbc", "4.2.2.RELEASE", "org.springframework/spring-jdbc/jars/spring-jdbc-4.2.2.RELEASE.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.springframework/spring-beans/jars/spring-beans-4.2.2.RELEASE.jar",
		"org.springframework/spring-core/jars/spring-core-4.2.2.RELEASE.jar",
		"commons-logging/commons-logging/jars/commons-logging-1.2.jar",
		"org.springframework/spring-tx/jars/spring-tx-4.2.2.RELEASE.jar"]>,
	<63, "com.sun.xml.bind", "jaxb-impl", "2.2.11", "com.sun.xml.bind/jaxb-impl/jars/jaxb-impl-2.2.11.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<64, "org.hibernate", "hibernate-validator", "5.2.2.Final", "org.hibernate/hibernate-validator/jars/hibernate-validator-5.2.2.Final.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"javax.validation/validation-api/jars/validation-api-1.1.0.Final.jar",
		"com.fasterxml/classmate/bundles/classmate-1.1.0.jar"]>,
	<65, "com.thoughtworks.xstream", "xstream", "1.4.8", "com.thoughtworks.xstream/xstream/jars/xstream-1.4.8.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"xmlpull/xmlpull/jars/xmlpull-1.1.3.1.jar",
		"xpp3/xpp3_min/jars/xpp3_min-1.1.4c.jar"]>,
	<66, "org.springframework", "spring-aop", "4.2.2.RELEASE", "org.springframework/spring-aop/jars/spring-aop-4.2.2.RELEASE.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"aopalliance/aopalliance/jars/aopalliance-1.0.jar",
		"org.springframework/spring-beans/jars/spring-beans-4.2.2.RELEASE.jar",
		"org.springframework/spring-core/jars/spring-core-4.2.2.RELEASE.jar",
		"commons-logging/commons-logging/jars/commons-logging-1.2.jar"]>,
	<67, "org.jboss.logging", "jboss-logging", "3.3.0.Final", "org.jboss.logging/jboss-logging/jars/jboss-logging-3.3.0.Final.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<68, "org.mortbay.jetty", "jetty", "6.1.26", "org.mortbay.jetty/jetty/jars/jetty-6.1.26.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.mortbay.jetty/jetty-util/jars/jetty-util-6.1.26.jar",
		"org.mortbay.jetty/servlet-api/jars/servlet-api-2.5-20081211.jar"]>,
	<69, "commons-dbcp", "commons-dbcp", "1.4", "commons-dbcp/commons-dbcp/jars/commons-dbcp-1.4.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"commons-pool/commons-pool/jars/commons-pool-1.5.4.jar"]>,
	<70, "commons-fileupload", "commons-fileupload", "1.3.1", "commons-fileupload/commons-fileupload/jars/commons-fileupload-1.3.1.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<71, "org.json", "json", "20150729", "org.json/json/jars/json-20150729.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<72, "org.easytesting", "fest-assert", "1.4", "org.easytesting/fest-assert/jars/fest-assert-1.4.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.easytesting/fest-util/jars/fest-util-1.1.6.jar"]>,
	<73, "org.springframework", "spring-tx", "4.2.2.RELEASE", "org.springframework/spring-tx/jars/spring-tx-4.2.2.RELEASE.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.springframework/spring-beans/jars/spring-beans-4.2.2.RELEASE.jar",
		"org.springframework/spring-core/jars/spring-core-4.2.2.RELEASE.jar",
		"commons-logging/commons-logging/jars/commons-logging-1.2.jar"]>,
	<74, "org.eclipse.jetty", "jetty-servlet", "9.3.5.v20151012", "org.eclipse.jetty/jetty-servlet/jars/jetty-servlet-9.3.5.v20151012.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.eclipse.jetty/jetty-security/jars/jetty-security-9.3.5.v20151012.jar",
		"org.eclipse.jetty/jetty-server/jars/jetty-server-9.3.5.v20151012.jar",
		"javax.servlet/javax.servlet-api/jars/javax.servlet-api-3.1.0.jar",
		"org.eclipse.jetty/jetty-http/jars/jetty-http-9.3.5.v20151012.jar",
		"org.eclipse.jetty/jetty-util/jars/jetty-util-9.3.5.v20151012.jar",
		"org.eclipse.jetty/jetty-io/jars/jetty-io-9.3.5.v20151012.jar"]>,
	<75, "org.scoverage", "scalac-scoverage-plugin_2.11", "1.1.1", "org.scoverage/scalac-scoverage-plugin_2.11/jars/scalac-scoverage-plugin_2.11-1.1.1.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.scala-lang.modules/scala-xml_2.11/bundles/scala-xml_2.11-1.0.1.jar"]>,
	<76, "org.apache.maven", "maven-model", "3.3.3", "org.apache.maven/maven-model/jars/maven-model-3.3.3.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<77, "org.spockframework", "spock-core", "1.0-groovy-2.4", "org.spockframework/spock-core/jars/spock-core-1.0-groovy-2.4.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"junit/junit/jars/junit-4.12.jar",
		"org.hamcrest/hamcrest-core/jars/hamcrest-core-1.3.jar"]>,
	<78, "org.projectlombok", "lombok", "1.16.6", "org.projectlombok/lombok/jars/lombok-1.16.6.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<79, "cglib", "cglib", "3.2.0", "cglib/cglib/jars/cglib-3.2.0.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.ow2.asm/asm/jars/asm-5.0.3.jar"]>,
	<80, "org.springframework", "spring-context-support", "4.2.2.RELEASE", "org.springframework/spring-context-support/jars/spring-context-support-4.2.2.RELEASE.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.springframework/spring-beans/jars/spring-beans-4.2.2.RELEASE.jar",
		"org.springframework/spring-core/jars/spring-core-4.2.2.RELEASE.jar",
		"commons-logging/commons-logging/jars/commons-logging-1.2.jar",
		"org.springframework/spring-context/jars/spring-context-4.2.2.RELEASE.jar",
		"org.springframework/spring-aop/jars/spring-aop-4.2.2.RELEASE.jar",
		"aopalliance/aopalliance/jars/aopalliance-1.0.jar",
		"org.springframework/spring-expression/jars/spring-expression-4.2.2.RELEASE.jar"]>,
	<81, "dom4j", "dom4j", "1.6.1", "dom4j/dom4j/jars/dom4j-1.6.1.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<82, "org.springframework", "spring-orm", "4.2.2.RELEASE", "org.springframework/spring-orm/jars/spring-orm-4.2.2.RELEASE.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.springframework/spring-beans/jars/spring-beans-4.2.2.RELEASE.jar",
		"org.springframework/spring-core/jars/spring-core-4.2.2.RELEASE.jar",
		"commons-logging/commons-logging/jars/commons-logging-1.2.jar",
		"org.springframework/spring-jdbc/jars/spring-jdbc-4.2.2.RELEASE.jar",
		"org.springframework/spring-tx/jars/spring-tx-4.2.2.RELEASE.jar"]>,
	<83, "org.scalacheck", "scalacheck_2.10", "1.12.5", "org.scalacheck/scalacheck_2.10/jars/scalacheck_2.10-1.12.5.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.scala-sbt/test-interface/jars/test-interface-1.0.jar"]>,
	<84, "org.powermock", "powermock-module-junit4", "1.6.3", "org.powermock/powermock-module-junit4/jars/powermock-module-junit4-1.6.3.jar", [
		"java-8-openjdk-amd64/jre/lib/","junit/junit/jars/junit-4.12.jar",
		"org.hamcrest/hamcrest-core/jars/hamcrest-core-1.3.jar",
		"org.powermock/powermock-module-junit4-common/jars/powermock-module-junit4-common-1.6.3.jar",
		"org.powermock/powermock-core/jars/powermock-core-1.6.3.jar",
		"org.powermock/powermock-reflect/jars/powermock-reflect-1.6.3.jar",
		"org.javassist/javassist/bundles/javassist-3.20.0-GA.jar"]>,
	<85, "org.apache.velocity", "velocity", "1.7", "org.apache.velocity/velocity/jars/velocity-1.7.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"commons-collections/commons-collections/jars/commons-collections-3.2.1.jar"]>,
	<86, "org.apache.httpcomponents", "httpcore", "4.4.4", "org.apache.httpcomponents/httpcore/jars/httpcore-4.4.4.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<87, "commons-configuration", "commons-configuration", "1.10", "commons-configuration/commons-configuration/jars/commons-configuration-1.10.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"commons-lang/commons-lang/jars/commons-lang-2.6.jar"]>,
	<88, "asm", "asm", "3.3.1", "asm/asm/jars/asm-3.3.1.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<89, "org.apache.felix", "org.apache.felix.scr.annotations", "1.9.12", "org.apache.felix/org.apache.felix.scr.annotations/jars/org.apache.felix.scr.annotations-1.9.12.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<90, "org.easymock", "easymockclassextension", "3.2", "org.easymock/easymockclassextension/jars/easymockclassextension-3.2.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<91, "org.aspectj", "aspectjrt", "1.8.7", "org.aspectj/aspectjrt/jars/aspectjrt-1.8.7.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<92, "org.apache.camel", "camel-core", "2.16.0", "org.apache.camel/camel-core/bundles/camel-core-2.16.0.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"com.sun.xml.bind/jaxb-core/jars/jaxb-core-2.2.11.jar",
		"com.sun.xml.bind/jaxb-impl/jars/jaxb-impl-2.2.11.jar"]>,
	<93, "xmlunit", "xmlunit", "1.6", "xmlunit/xmlunit/jars/xmlunit-1.6.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<94, "org.javassist", "javassist", "3.20.0-GA", "org.javassist/javassist/bundles/javassist-3.20.0-GA.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<95, "com.google.protobuf", "protobuf-java", "2.6.1", "com.google.protobuf/protobuf-java/bundles/protobuf-java-2.6.1.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<96, "org.codehaus.plexus", "plexus-container-default", "1.6", "org.codehaus.plexus/plexus-container-default/jars/plexus-container-default-1.6.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"org.apache.xbean/xbean-reflect/bundles/xbean-reflect-3.7.jar",
		"com.google.collections/google-collections/jars/google-collections-1.0.jar"]>,
	<97, "org.hibernate.javax.persistence", "hibernate-jpa-2.0-api", "1.0.1.Final", "org.hibernate.javax.persistence/hibernate-jpa-2.0-api/jars/hibernate-jpa-2.0-api-1.0.1.Final.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>,
	<98, "org.reflections", "reflections", "0.9.10", "org.reflections/reflections/jars/reflections-0.9.10.jar", [
		"java-8-openjdk-amd64/jre/lib/",
		"com.google.code.findbugs/annotations/jars/annotations-2.0.1.jar"]>,
	<99, "com.sun.jersey", "jersey-server", "1.19", "com.sun.jersey/jersey-server/jars/jersey-server-1.19.jar", [
		"java-8-openjdk-amd64/jre/lib/"]>
];
