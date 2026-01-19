<%@ include file="/include-internal.jsp" %><%@
    taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %><%@
    taglib prefix="responsible" uri="/WEB-INF/functions/resp" %><%@
    taglib prefix="resp" tagdir="/WEB-INF/tags/responsible"

%><jsp:useBean id="buildType" type="jetbrains.buildServer.serverSide.SBuildType" scope="request"
/><resp:formContent buildType="${buildType}" currentUser="${currentUser}"
  ><resp:buildTypeCheckBox buildType="${buildType}" checked="true"
  /><c:forEach var="bt" items="${buildType.project.ownBuildTypes}"
    ><c:if test="${bt.status.failed and bt != buildType and not
                   (responsible:isUserResponsible(bt.responsibilityInfo, currentUser) or
                    responsible:isUserFixed(bt.responsibilityInfo, currentUser))}"
      ><resp:buildTypeCheckBox buildType="${bt}"
    /></c:if
  ></c:forEach
></resp:formContent>