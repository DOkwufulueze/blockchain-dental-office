<template>
  <div class="wrapper">
    <div id="applications">
      <div class="title">Applications</div>

      <div class="applications-result-section">
        <div class="applications-trigger-section">
          <div class="applications-trigger" :class="addClass(1, 'active')" data-open="applications-scan-section" data-type="1" @click="switchView">Scan Applications</div>
          <div class="applications-trigger" :class="addClass(2, 'active')" data-open="applications-treatment-section" data-type="2" @click="switchView">Treatment Applications</div>
        </div>
        <div class="applications-view-section">
          <div class="applications-query-section">
            <div class="applications-entry-item">
              <div class="applications-entry-param">Application Type</div>
              <div class="applications-entry-value">
                <select id="applications-type" class="applications-list">
                  <option>Unaccepted Applications</option>
                  <option>Accepted Applications</option>
                </select>
              </div>
            </div>
          </div>

          <div class="applications-scan-section" :class="addClass(1, 'showing')" id="applications-scan-section"></div>
          <div class="applications-treatment-section" :class="addClass(2, 'showing')" id="applications-treatment-section"></div>
        </div>
      </div>

      <div class="applications-navigation">
        <div v-if="isThereMore" @click="showNextPage" class="applications-fetch-next">Next ></div>
        <div v-if="pageNumber !== 1" @click="showPreviousPage" class="applications-fetch-previous">< Previous</div>
      </div>
    </div>
  </div>
</template>

<script>
  const BigNumber = require('bignumber.js')
  export default {
    computed: {
      user () {
        return this.$root.user
      },
      isThereMore () {
        return this.$store.state.searchResult[Number(this.$route.query.aTI || 1) === 1 ? 'fetchScanApplications' : 'fetchTreatmentApplications'].totalNumberAvailable > (this.pageNumber * this.perPage)
      },
      pageNumber () {
        return (Number(this.$route.query.o || 0) / this.perPage) + 1
      },
      nextOffset () {
        return (this.pageNumber * this.perPage)
      },
      currentOffset () {
        return (this.nextOffset - this.perPage)
      },
      previousOffset () {
        return (this.currentOffset - this.perPage)
      },
      perPage () {
        return 5
      }
    },
    methods: {
      addClass (check, value) {
        return Number(this.$route.query.aTI) === check || (!this.$route.query.aTI && check === 1) ? value : ''
      },
      switchView (evt) {
        const target = evt.target
        const whichApplication = document.querySelector('#applications-type').selectedIndex
        if (!(target.classList.contains('active'))) {
          document.querySelector('.showing').classList.remove('showing')
          document.querySelector('.active').classList.remove('active')
          target.classList.add('active')
          document.querySelector(`.${target.dataset.open}`).classList.add('showing')
          const serviceType = Number(target.dataset.type)
          if (whichApplication === 0) {
            this.fetchApplications(null, this.currentOffset, this.$store.state.searchResult[serviceType === 1 ? 'fetchScanApplications' : 'fetchTreatmentApplications'].seed, 1, serviceType)
          } else if (whichApplication === 1) {
            this.fetchPostApplications(null, this.currentOffset, this.$store.state.searchResult[serviceType === 1 ? 'fetchCases' : 'fetchTreatments'].seed, 1, serviceType)
          }
        }
      },
      setEventListeners () {
        const _this = this
        const applicationsPage = document.querySelector('#applications')

        applicationsPage.addEventListener('change', function (evt) {
          let target = evt.target
          const applicationTypeId = Number(_this.$route.query.aTI || 1)
          switch (target.id) {
            case 'applications-type':
              if (Number(evt.target.selectedIndex) === 0) {
                _this.fetchApplications(evt, 0, null, 1, applicationTypeId)
              } else {
                _this.fetchPostApplications(evt, 0, null, 1, applicationTypeId)
              }

              break
          }
        })

        applicationsPage.addEventListener('click', function (evt) {
          let target = evt.target
          switch (true) {
            case (target.classList.contains('accept-application')):
              _this.acceptApplication(evt)
              break
            case (target.classList.contains('release-fund')):
              _this.releaseFund(evt)
              break
            case target.classList.contains('applications-only-patient'):
              const dentistId = _this.$store.state.searchResult.fetchCases.data[_this.currentOffset][target.dataset.sn].userObject.coinbase
              if (_this.user.isPatient && dentistId) {
                const rating = target.dataset.rating
                _this.writeDentistRating(evt, dentistId, rating)
              } else {
                console.log(':::You have to be a patient of a doctor before you can rate them.')
              }

              break
          }
        })
      },
      writeDentistRating (evt, dentistId, rating) {
        const applicationTypeId = Number(this.$route.query.aTI || 1)
        this.disableNecessaryButtons(evt)
        this.beginWait(document.querySelector('.wrapper'))
        this.$root.callToWriteData({
          requestParams: {
            dentistId,
            rating: rating
          },
          methodName: 'writeDentistRating',
          contractIndexToUse: 'UserWriter',
          managerIndex: 'userManager',
          callback: (status) => {
            this.endWait(document.querySelector('.wrapper'))
            this.enableNecessaryButtons(evt)
            this.notify(status ? 'Rating Successfully added' : 'Unable to add Rating')
            this.fetchPostApplications(evt, 0, null, 1, applicationTypeId)
          }
        })
      },
      acceptApplication (evt) {
        const sn = evt.target.dataset.params
        const applicationTypeId = Number(this.$route.query.aTI || 1)
        const application = this.$store.state.searchResult[applicationTypeId === 1 ? 'fetchScanApplications' : 'fetchTreatmentApplications'].data[this.currentOffset][sn]

        fetch(EXCHANGE_RATE_API)
        .then(response => response.json())
        .then((JSONResponse) => {
          const USDExchange = JSONResponse[0].price_usd
          const quoteInEther = application.quote / USDExchange
          const quoteInWei = this.$store.state.web3.instance().toWei(quoteInEther, 'ether')
          const tempTotalFee = new BigNumber(quoteInWei)
          const percentage = new BigNumber(Number(applicationTypeId === 1 ? (application.ODLLSPP / 100) : (application.ODLLTPP / 100)))
          const ODLLFee = tempTotalFee.times(percentage)
          const dentistFee = tempTotalFee.minus(ODLLFee)
          const totalFee = ODLLFee.plus(dentistFee)
          console.log(ODLLFee, dentistFee, totalFee)
          this.scrollToTop()
          this.disableNecessaryButtons(evt)
          this.beginWait(document.querySelector('.wrapper'))
          this.$root.callToWriteData({
            requestParams: {
              dentistId: application.userId,
              applicationId: application.applicationId,
              quote: totalFee.toString(),
              ODLLFee: ODLLFee.toString(),
              dentistFee: dentistFee.toString()
            },
            managerIndex: 'serviceManager', // which of the contract managers to use
            contractIndexToUse: applicationTypeId === 1 ? 'ScanApplicationWriter2' : 'TreatmentApplicationWriter2',
            value: totalFee,
            methodName: applicationTypeId === 1 ? 'acceptScanApplication' : 'acceptTreatmentApplication',
            callback: (status) => {
              this.endWait(document.querySelector('.wrapper'))
              this.enableNecessaryButtons(evt)
              if (status) this.fetchApplications(null, this.currentOffset, this.$store.state.searchResult[applicationTypeId === 1 ? 'fetchScanApplications' : 'fetchTreatmentApplications'].seed, 1, Number(this.$route.query.aTI || 1))
              this.notify(status ? 'Application Successfully accepted' : 'Unable to accept Application')
            }
          })
        })
        .catch((e) => console.error(e))
      },
      fetchApplications (evt, offset = 0, seed = null, direction = 1, applicationTypeId = 1) {
        const fetchQuery = {
          type: applicationTypeId === 1 ? 'fetchScanApplications' : 'fetchTreatmentApplications',
          requestParams: {
            userId: this.user.coinbase,
            offset,
            limit: this.perPage,
            seed: seed || Math.random()
          },
          managerIndex: 'searchManager', // which of the contract managers to use
          contractIndexToUse: applicationTypeId === 1 ? 'ScanApplicationReader' : 'TreatmentApplicationReader',
          methodName: applicationTypeId === 1 ? 'fetchScanApplicationsForPatient' : 'fetchTreatmentApplicationsForPatient',
          callOnEach: 'getApplicationDetail',
          callOnEachParams: applicationId => ({applicationTypeId, applicationId: applicationId.toNumber()})
        }

        this.$router.push({
          path: '/view-applications',
          query: {
            o: fetchQuery.offset,
            l: fetchQuery.limit,
            sd: fetchQuery.seed,
            aTI: applicationTypeId
          }
        })
        const offsetData = this.$store.state.searchResult[fetchQuery.type].data[offset]
        if (direction < 0 && offsetData && offsetData.length > 0) {
          this.populateResults(offsetData, applicationTypeId)
        } else {
          this.getApplications(evt, fetchQuery)
        }
      },
      getApplications (evt, fetchQuery) {
        const applicationTypeId = Number(this.$route.query.aTI || 1)
        const resultSection = document.querySelector(`.${applicationTypeId === 1 ? 'applications-scan-section' : 'applications-treatment-section'}`)
        this.clearDOMElementChildren(resultSection)
        this.askUserToWaitWhileWeSearch(applicationTypeId)
        this.disableNecessaryButtons()
        this.$root.callToFetchDataObjects({
          fetchQuery,
          callback: (result = null, isCompleted = false) => {
            // update result view
            if (isCompleted) {
              if (document.querySelector('.applications-wait-overlay')) document.querySelector('.applications-wait-overlay').remove()
              this.enableNecessaryButtons()
            }

            if (result) {
              if (result.status === 1) this.appendResult(result, applicationTypeId)
            } else {
              this.informOfNoApplication(applicationTypeId)
            }
          }
        })
      },
      fetchPostApplications (evt, offset = 0, seed = null, direction = 1, applicationTypeId = 1) {
        const fetchQuery = {
          type: applicationTypeId === 1 ? 'fetchCases' : 'fetchTreatments',
          requestParams: {
            userId: this.user.coinbase,
            offset,
            limit: this.perPage,
            seed: seed || Math.random()
          },
          managerIndex: 'searchManager', // which of the contract managers to use
          contractIndexToUse: 'PostApplicationReader',
          methodName: applicationTypeId === 1 ? 'fetchCasesForPatient' : 'fetchTreatmentsForPatient',
          callOnEach: applicationTypeId === 1 ? 'getCaseDetail' : 'getTreatmentDetail',
          callOnEachParams: caseId => ({applicationTypeId, caseId: caseId.toNumber()})
        }

        this.$router.push({
          path: '/view-applications',
          query: {
            o: fetchQuery.offset,
            l: fetchQuery.limit,
            sd: fetchQuery.seed,
            aTI: applicationTypeId
          }
        })
        const offsetData = this.$store.state.searchResult[fetchQuery.type].data[offset]
        if (direction < 0 && offsetData && offsetData.length > 0) {
          this.populatePostApplicationResults(offsetData, applicationTypeId)
        } else {
          this.getPostApplications(evt, fetchQuery)
        }
      },
      getPostApplications (evt, fetchQuery) {
        const applicationTypeId = Number(this.$route.query.aTI || 1)
        const resultSection = document.querySelector(`.${applicationTypeId === 1 ? 'applications-scan-section' : 'applications-treatment-section'}`)
        this.clearDOMElementChildren(resultSection)
        this.askUserToWaitWhileWeSearch(applicationTypeId)
        this.disableNecessaryButtons()
        this.$root.callToFetchDataObjects({
          fetchQuery,
          callback: (result = null, isCompleted = false) => {
            // update result view
            if (isCompleted) {
              if (document.querySelector('.applications-wait-overlay')) document.querySelector('.applications-wait-overlay').remove()
              this.enableNecessaryButtons()
            }

            if (result) {
              result.applicationObject.SN = result.SN
              result.paymentObject.SN = result.SN
              this.appendPostApplicationResult(result, applicationTypeId)
            } else {
              this.informOfNoPostApplication(applicationTypeId)
            }
          }
        })
      },
      releaseFund (evt) {
        const sn = evt.target.dataset.params
        const applicationTypeId = Number(this.$route.query.aTI || 1)
        const postApplication = this.$store.state.searchResult[applicationTypeId === 1 ? 'fetchCases' : 'fetchTreatments'].data[this.currentOffset][sn]
        this.scrollToTop()
        this.disableNecessaryButtons(evt)
        this.beginWait(document.querySelector('.wrapper'))
        this.$root.callToWriteData({
          requestParams: {
            userId: this.user.coinbase,
            dentistId: postApplication.userObject.coinbase,
            paymentId: postApplication.paymentId
          },
          managerIndex: 'serviceManager', // which of the contract managers to use
          contractIndexToUse: 'Escrow',
          methodName: applicationTypeId === 1 ? 'releaseFundForScan' : 'releaseFundForTreatment',
          callback: (status) => {
            this.endWait(document.querySelector('.wrapper'))
            this.enableNecessaryButtons(evt)
            if (status) this.fetchPostApplications(null, this.currentOffset, this.$store.state.searchResult[applicationTypeId === 1 ? 'fetchScanApplications' : 'fetchTreatmentApplications'].seed, 1, Number(this.$route.query.aTI || 1))
            this.notify(status ? 'Fund Successfully released' : 'Unable to release Fund')
          }
        })
      },
      populateResults (results, resultType = 1) {
        if (typeof resultType === 'object' && resultType.toNumber) resultType = resultType.toNumber()
        const resultSection = document.querySelector(`.${resultType === 1 ? 'applications-scan-section' : 'applications-treatment-section'}`)
        this.clearDOMElementChildren(resultSection)
        results.forEach((result) => {
          const resultDOMElement = this.createResultDOMElement(result)
          resultSection.appendChild(resultDOMElement)
          resultDOMElement.querySelector('.applications-gravatar-section').appendChild(result.userObject.avatarCanvas)
        })
      },
      populatePostApplicationResults (results, resultType = 1) {
        if (typeof resultType === 'object' && resultType.toNumber) resultType = resultType.toNumber()
        const resultSection = document.querySelector(`.${resultType === 1 ? 'applications-scan-section' : 'applications-treatment-section'}`)
        this.clearDOMElementChildren(resultSection)
        results.forEach((result) => {
          const resultDOMElement = this.createPostApplicationResultDOMElement(result)
          resultSection.appendChild(resultDOMElement)
          resultDOMElement.querySelector('.applications-gravatar-section').appendChild(result.userObject.avatarCanvas)
        })
      },
      appendResult (result, resultType = 1) {
        if (typeof resultType === 'object' && resultType.toNumber) resultType = resultType.toNumber()
        const resultDOMElement = this.createResultDOMElement(result)
        const resultSection = document.querySelector(`.${Number(resultType) === 1 ? 'applications-scan-section' : 'applications-treatment-section'}`)
        resultSection.appendChild(resultDOMElement)
        if (resultDOMElement.querySelector('.applications-gravatar-section')) resultDOMElement.querySelector('.applications-gravatar-section').appendChild(result.userObject.avatarCanvas)
      },
      appendPostApplicationResult (result, resultType = 1) {
        if (typeof resultType === 'object' && resultType.toNumber) resultType = resultType.toNumber()
        const resultDOMElement = this.createPostApplicationResultDOMElement(result)
        const resultSection = document.querySelector(`.${Number(resultType) === 1 ? 'applications-scan-section' : 'applications-treatment-section'}`)
        resultSection.appendChild(resultDOMElement)
        if (resultDOMElement.querySelector('.applications-gravatar-section')) resultDOMElement.querySelector('.applications-gravatar-section').appendChild(result.userObject.avatarCanvas)
      },
      clearDOMElementChildren (DOMElement) {
        while (DOMElement.hasChildNodes()) {
          DOMElement.firstChild.remove()
        }
      },
      showNextPage () {
        const applicationTypeId = Number(this.$route.query.aTI || 1)
        this.fetchApplications(null, this.nextOffset, this.$store.state.searchResult[applicationTypeId === 1 ? 'fetchScanApplications' : 'fetchTreatmentApplications'].seed, 1, applicationTypeId)
      },
      showPreviousPage () {
        const applicationTypeId = Number(this.$route.query.aTI || 1)
        this.fetchApplications(null, this.previousOffset, this.$store.state.searchResult[applicationTypeId === 1 ? 'fetchScanApplications' : 'fetchTreatmentApplications'].seed, -1, applicationTypeId)
      },
      getPageIndex (offset = 0) {
        return offset / this.perPage
      },
      askUserToWaitWhileWeSearch (applicationTypeId = 1) {
        if (document.querySelector('.applications-wait-overlay')) document.querySelector('.applications-wait-overlay').remove()
        if (document.querySelector('.no-application')) document.querySelector('.no-application').remove()
        let waitOverlayDOMElement = this.createWaitOverlayDOMElement(applicationTypeId)
        document.querySelector('.applications-result-section').appendChild(waitOverlayDOMElement)
      },
      informOfNoApplication (applicationTypeId = 1) {
        if (document.querySelector('.no-application')) document.querySelector('.no-application').remove()
        let noServiceDOMElement = this.createNoApplicationDOMElement(applicationTypeId)
        if (document.querySelector('.applications-result-section')) document.querySelector('.applications-result-section').appendChild(noServiceDOMElement)
      },
      informOfNoPostApplication (applicationTypeId = 1) {
        if (document.querySelector('.no-application')) document.querySelector('.no-application').remove()
        let noServiceDOMElement = this.createNoPostApplicationDOMElement(applicationTypeId)
        if (document.querySelector('.applications-result-section')) document.querySelector('.applications-result-section').appendChild(noServiceDOMElement)
      },
      createWaitOverlayDOMElement (applicationTypeId = 1) {
        const DOMELement = new DOMParser().parseFromString(`
          <div class="applications-wait-overlay">
            <div class="applications-wait-message">Please Wait... We're searching the blockchain for your ${applicationTypeId === 1 ? 'Scan' : 'Treatment'} applications.</div>
            <div class="spin"></div>
          </div>
        `, 'text/html')

        return DOMELement.body.firstChild
      },
      createNoApplicationDOMElement (applicationTypeId = 1) {
        const DOMELement = new DOMParser().parseFromString(`
          <div class="no-application">
            <div class="no-application-message">
              It appears you have no ${applicationTypeId === 1 ? 'Scan' : 'Treatment'} application on the blockchain.
            </div>
          </div>
        `, 'text/html')

        return DOMELement.body.firstChild
      },
      createNoPostApplicationDOMElement (applicationTypeId = 1) {
        const DOMELement = new DOMParser().parseFromString(`
          <div class="no-application">
            <div class="no-application-message">
              It appears you have no ${applicationTypeId === 1 ? 'Case' : 'Treatment'} on the blockchain.
            </div>
          </div>
        `, 'text/html')

        return DOMELement.body.firstChild
      },
      createResultDOMElement (result) {
        const userObject = result.userObject
        const resultDOMElement = new DOMParser().parseFromString(`
          <div class="applications-result">
            <div class="applications-gravatar-section"></div>
            <div class="applications-about-section">
              <div class="applications-service-name">Application for: <span>${result.serviceName}</span></div>
              <div class="applications-name">Dentist: <span>${userObject.name || 'Name: Not Supplied'}</span></div>
              <div class="applications-company-name">Company: <span>${userObject.companyName || 'Not Supplied'}</span></div>
              <div class="applications-address">Address: <span>${userObject.address || 'Not Supplied'}</span></div>
              <div class="applications-quote">Quote: <span>$${result.quote}</span></div>
              <div class="applications-appointment-date">Date: <span>${formatDate(new Date(Number(result.appointmentDate)))}</span></div>
              <div class="applications-appointment-time">Time: <span>${result.appointmentTime}</span></div>
              <div class="applications-comment">Comment: <span>${result.comment}</span></div>
              <input type="button" value="Accept" class="applications-button accept-application" data-params="${result.SN}">
            </div>
          </div>
        `, 'text/html').body.firstChild
        return resultDOMElement
      },
      createPostApplicationResultDOMElement (result) {
        const userObject = result.userObject
        console.log(result)
        const resultDOMElement = new DOMParser().parseFromString(`
          <div class="applications-result">
            <div class="applications-gravatar-section"></div>
            <div class="applications-about-section">
              <div class="applications-service-name">Application for: <span>${result.serviceName}</span></div>
              <div class="applications-name">Dentist: <span>${userObject.name || 'Name: Not Supplied'}</span></div>
              <div class="applications-company-name">Company: <span>${userObject.companyName || 'Not Supplied'}</span></div>
              <div class="applications-address">Address: <span>${userObject.address || 'Not Supplied'}</span></div>
              <div class="applications-quote">Amount: <span>$${result.applicationObject.quote}</span></div>
              <div class="applications-status">Status: <span>${result.paymentObject.status === 3 ? 'Paid Dentist In Full' : 'Paid into Escrow'}</span></div>
              ${this.createAverageRatingDOMElement(userObject.averageRating, result.SN).outerHTML}
              ${result.paymentObject.status === 2 ? '<input type="button" value="Release Fund" class="applications-button release-fund" data-params="' + result.SN + '">' : ''}
            </div>
          </div>
        `, 'text/html').body.firstChild
        return resultDOMElement
      },
      createAverageRatingDOMElement (averageRating, SN) {
        const ratingsArray = []
        for (let i = 0; i < 5; i++) {
          ratingsArray.push(`
            <div data-rating="${i + 1}" data-sn="${SN}" class="applications-rating ${i < averageRating ? 'filled' : ''} ${this.user.isPatient ? 'applications-only-patient' : ''}"></div>
          `)
        }

        return new DOMParser().parseFromString(`
          <div class="applications-average-rating">${ratingsArray.join(' ')}</div>
        `, 'text/html').body.firstChild
      },
      disableNecessaryButtons (evt = null) {
        Array.from(document.querySelectorAll('.applications-button')).forEach(button => this.disableButton(button))
      },
      enableNecessaryButtons (evt = null) {
        Array.from(document.querySelectorAll('.applications-button')).forEach(button => this.enableButton(button))
      },
      disableButton (target) {
        target.disabled = true
        target.style.cursor = 'not-allowed'
        target.style.background = '#adcddf'
      },
      enableButton (target) {
        target.disabled = false
        target.style.cursor = 'pointer'
        target.style.background = '#29aae1'
      },
      notify (message) {
        console.log(message)
      },
      beginWait (target) {
        target.classList.add('wait')
      },
      endWait (target) {
        target.classList.remove('wait')
      },
      scrollToTop () {
        $('html, body').animate({scrollTop: '0px'}, 500)
      }
    },
    mounted: function () {
      const applicationTypeId = Number(this.$route.query.aTI || 1)
      this.setEventListeners()
      this.getApplications(null, {
        type: applicationTypeId === 1 ? 'fetchScanApplications' : 'fetchTreatmentApplications',
        requestParams: {
          userId: this.user.coinbase,
          offset: Number(this.$route.query.o || 0),
          limit: Number(this.$route.query.l || this.perPage),
          seed: Number(this.$route.query.sd || Math.random())
        },
        managerIndex: 'searchManager', // which of the contract managers to use
        contractIndexToUse: applicationTypeId === 1 ? 'ScanApplicationReader' : 'TreatmentApplicationReader',
        methodName: applicationTypeId === 1 ? 'fetchScanApplicationsForPatient' : 'fetchTreatmentApplicationsForPatient',
        callOnEach: 'getApplicationDetail',
        callOnEachParams: applicationId => ({applicationTypeId, applicationId: applicationId.toNumber()})
      })
    }
  }

  import $ from 'jquery'
  import {formatDate} from '../../../../../util/others'
  import {EXCHANGE_RATE_API} from '../../../../../util/constants'
</script>

<style scoped>
  .wrapper {
    background: #ffffff;
    height: 100%;
    min-height: 80vh;
    width: 100%;
    display: flex;
    flex-direction: column;
  }

  .wait:before {
    content: '';
    display: block;
    position: relative;
    width: 200px;
    margin: auto;
    height: 4px;
    background-color: #f4903e;
    animation: wait-keyframe 4.2s infinite
  }

  @keyframes wait-keyframe {
    0% {width: 20%;}
    25% {width: 40%;}
    50% {width: 60%;}
    75% {width: 80%;}
    100% {width: 100%;}
  }

  #applications {
    background: #ffffff;
    min-height: 70vh;
    width: 90%;
    font-size: 12px;
    margin: 30px auto;
    color: #7a7a7a;
    display: flex;
    flex-direction: column;
  }

  .title {
    height: 40px;
    line-height: 40px;
    width: 100%;
    text-align: left;
    font-size: 20px;
    margin-bottom: 10px;
  }

  .applications-query-section {
    width: 100%;
    height: 100px;
    margin-bottom: 30px;
    background: #ffffff;
    display: flex;
    flex-direction: row;
    justify-content: space-between;
  }

  .applications-entry-item {
    height: 60px;
    display: inline-block;
    /*margin-right: 10px;*/
    margin-top: 30px;
    margin-bottom: 30px;
    justify-content: center;
    min-width: 33%;
  }

  .applications-entry-param {
    color: #7f7f7f;
    margin-bottom: 5px;
    height: 20px;
    font-size: 14px;
    line-height: 20px;
  }

  .applications-list {
    height: 30px;
    width: 100%;
    background: #ffffff;
    outline: none;
    border: 1px solid #d3d3d3;
    color: #7f7f7f;
  }

  .error {
    border: 1px solid #f18787 !important;
  }

  .applications-button {
    padding: 2px;
    text-align: center;
    outline: 0px;
    border: 0px;
    cursor: pointer;
    height: 30px;
    line-height: 30px;
    width: 100px;
    background: #29aae1;
    color: #ffffff;
    display: inline-block;
  }

  .applications-result-section {
    position: relative;
    min-height: 300px;
  }

  .applications-trigger-section {
    width: 100%;
    height: 40px;
    background: #edefef;
    display: flex;
    flex-direction: row;
    justify-content: center;
    align-items: center;
  }

  .applications-trigger {
    height: 35px;
    width: 50%;
    margin-top: 5px;
    cursor: pointer;
    font-size: 16px;
    line-height: 35px;
    text-align: center;
  }

  .active {
    background: #ffffff;
    cursor: auto;
  }

  .applications-view-section {
    background: #ffffff;
    min-height: 260px;
    width: 100%;
  }

  .applications-scan-section, .applications-treatment-section {
    width: 100%;
    min-height: 260px;
    display: none;
  }

  .showing {
    display: block;
  }

  .applications-navigation {
    width: 100%;
    float: right;
  }

  .applications-fetch-next, .applications-fetch-previous {
    cursor: pointer;
    color: #6592ad;
    background: #ffffff;
    height: 30px;
    line-height: 30px;
    width: 120px;
    display: inline-block;
    float: right;
    text-align: center;
    margin-right: 5px;
    font-size: 14px;
  }

  .applications-fetch-next:hover, .applications-fetch-previous:hover {
    background: #dae3e8;
  }
</style>

<style>
  .no-application {
    position: absolute;
    top: 160px;
    width: 100%;
    min-height: 260px;
    text-align: center;
    font-size: 16px;
  }

  .no-application-message {
    height: 30px;
    position: relative;
    top: 110px;
  }

  .applications-wait-overlay {
    position: absolute;
    top: 160px;
    width: 100%;
    height: 100%;
    text-align: center;
    font-size: 16px;
    height: 260px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    background: rgba(255, 255, 255, 0.9);
  }

  .applications-wait-message {
    height: 30px;
    line-height: 30px;
    position: relative;
    font-size: 16px;
  }

  .spin {
    height: 45px;
    width: 45px;
    border-radius: 45px;
    border-top: 3px solid #3286b0;
    border-right: 3px solid #3286b0;
    border-bottom: 3px solid #ffffff;
    border-left: transparent;
    animation: odll-spin 1.2s cubic-bezier(0.2, 0.92, 0.94, 0.9) infinite;
    position: relative;
  }

  @keyframes odll-spin {
    0% {
      transform: rotate(0deg);
    }

    100% {
      transform: rotate(360deg);
    }
  }

  .applications-result {
    width: 95%;
    border-bottom: 1px solid #a7a7a7;
    min-height: 180px;
    padding: 10px 0px;
    display: block;
    float: left;
  }

  .applications-gravatar-section {
    width: 60px;
    height: 60px;
    float: left;
    display: inline-block;
    margin-right: 10px;
    border: 1px solid #c3c3c3;
    border-radius: 6px;
    padding: 3px;
  }

  .applications-gravatar-section > canvas {
    height: 100%;
    width: 100%;
    border-radius: 6px;
  }

  .applications-about-section {
    width: 80%;
    display: inline-block;
    float: left;
  }

  .applications-about-section > div {
    display: block;
    height: 20px;
    line-height: 20px;
    font-size: 14px;
    text-align: left;
    width: 100%;
    font-weight: bold;
  }

  .applications-about-section > div span {
    font-weight: normal;
  }

  .applications-about-section > .applications-comment {
    height: auto;
  }

  .applications-profile-link {
    font-size: 10px !important;
    color: #bfced9;
    cursor: pointer;
  }

  .applications-service-name {
    width: 50%;
    height: 40px;
    font-size: 20px;
    line-height: 40px;
  }

  .applications-service-name span {
    color: #115588;
  }

  .applications-quote {
    width: 50%;
    height: 40px;
    font-size: 16px;
    line-height: 40px;
  }

  .applications-average-rating {
    width: 100% !important;
    margin: 20px 0px;
  }

  .applications-average-rating > div {
    background: url(/static/images/star_line.png) no-repeat;
    background-size: contain;
    height: 20px;
    width: 20px;
    display: inline-block;
    float: left;
  }

  .applications-average-rating > div.applications-only-patient {
    cursor: pointer;
  }

  .applications-average-rating:hover > div.applications-only-patient {
    background: url(/static/images/star.png) no-repeat;
    background-size: contain;
  }

  .applications-average-rating > div.applications-only-patient:hover {
    background: url(/static/images/star.png) no-repeat;
    background-size: contain;
  }

  .applications-average-rating > div.applications-only-patient:hover ~ div.applications-only-patient {
    background: url(/static/images/star_line.png) no-repeat;
    background-size: contain;
  }

  .applications-average-rating > .filled {
    background: url(/static/images/star.png) no-repeat;
    background-size: contain;
  }

  .applications-button {
    padding: 0px 2px;
    text-align: center;
    outline: 0px;
    border: 0px;
    cursor: pointer;
    height: 30px;
    line-height: 30px;
    width: 100px;
    background: #29aae1;
    color: #ffffff;
    /*margin-left: 10px;*/
    display: inline-block;
  }

  .accept-application {
    background: #3285b1 !important;
    text-decoration: none;
    margin: 20px 10px 0px 0px !important;
  }
</style>
